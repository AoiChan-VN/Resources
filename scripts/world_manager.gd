extends Node3D
class_name WorldManager

# Khoảng cách hiển thị tính theo số lượng Chunk xung quanh người chơi (Render Distance)
const RENDER_DISTANCE: int = 4
const CHUNK_WIDTH: int = 16
const CHUNK_HEIGHT: int = 64

@export var player: Node3D = null
@export var terrain_material: Material = null

var _noise: FastNoiseLite = FastNoiseLite.new()
var _active_chunks: Dictionary = {} # Định dạng lưu trữ: {Vector2i: Chunk}
var _chunks_in_progress: Array[Vector2i] = []
var _saved_world_data: Dictionary = {} # Dữ liệu lưu trữ nạp từ bộ nhớ máy
var _mutex: Mutex = Mutex.new()
var _current_player_chunk: Vector2i = Vector2i(99999, 99999)

func _ready() -> void:
	if player == null:
		push_error("[WorldManager] Lỗi: Node Player chưa được gán vào WorldManager.")
		return
		
	# Nạp toàn bộ dữ liệu lưu trữ cũ từ file nhị phân nếu có trước khi sinh địa hình mới
	_saved_world_data = SaveSystem.load_world()
	
	_initialize_noise_generator()
	_update_world_generation()

func _process(_delta: float) -> void:
	if player == null:
		return
	
	var p_pos: Vector3 = player.global_position
	var p_chunk_x: int = floori(p_pos.x / float(CHUNK_WIDTH))
	var p_chunk_z: int = floori(p_pos.z / float(CHUNK_WIDTH))
	var new_player_chunk: Vector2i = Vector2i(p_chunk_x, p_chunk_z)
	
	if new_player_chunk != _current_player_chunk:
		_current_player_chunk = new_player_chunk
		_update_world_generation()

# Kích hoạt lưu dữ liệu thế giới nhị phân (Có thể gọi từ nút Save trên UI di động)
func trigger_save_world() -> void:
	_mutex.lock()
	var success: bool = SaveSystem.save_world(_active_chunks)
	_mutex.unlock()
	
	if success:
		print("[WorldManager] Dữ liệu địa hình đã được đồng bộ nhị phân xuống bộ nhớ Mobile thành công.")
	else:
		push_error("[WorldManager] Quá trình ghi nhớ dữ liệu gặp sự cố hệ thống.")

func _initialize_noise_generator() -> void:
	_noise.seed = 1337
	_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	_noise.frequency = 0.015
	_noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	_noise.fractal_octaves = 4
	_noise.fractal_lacunarity = 2.0
	_noise.fractal_gain = 0.5

func _update_world_generation() -> void:
	var loaded_chunks: Array[Vector2i] = []
	
	# Quét và gửi yêu cầu sinh các Chunk mới nằm trong tầm nhìn
	for x in range(-RENDER_DISTANCE, RENDER_DISTANCE + 1):
		for z in range(-RENDER_DISTANCE, RENDER_DISTANCE + 1):
			var target_chunk_pos: Vector2i = _current_player_chunk + Vector2i(x, z)
			loaded_chunks.append(target_chunk_pos)
			
			_mutex.lock()
			var is_active: bool = _active_chunks.has(target_chunk_pos)
			var is_building: bool = _chunks_in_progress.has(target_chunk_pos)
			_mutex.unlock()
			
			if not is_active and not is_building:
				_mutex.lock()
				_chunks_in_progress.append(target_chunk_pos)
				_mutex.unlock()
				
				# Đẩy tác vụ sinh dữ liệu sang luồng phụ an toàn
				WorkerThreadPool.submit_task(_thread_generate_chunk.bind(target_chunk_pos))
				
	_unload_distant_chunks(loaded_chunks)

# Hàm xử lý bất đồng bộ chạy hoàn toàn trên Thread riêng biệt
func _thread_generate_chunk(c_pos: Vector2i) -> void:
	var blocks_data: Array = []
	
	# Kiểm tra xem dữ liệu Chunk này có sẵn trong file Save nhị phân cũ hay không
	_mutex.lock()
	var has_saved_data: bool = _saved_world_data.has(c_pos)
	if has_saved_data:
		blocks_data = _saved_world_data[c_pos]
	_mutex.unlock()
	
	# Nếu không có dữ liệu cũ, tiến hành chạy thuật toán sinh địa hình tự nhiên
	if not has_saved_data:
		blocks_data.resize(CHUNK_WIDTH)
		var world_x_offset: int = c_pos.x * CHUNK_WIDTH
		var world_z_offset: int = c_pos.y * CHUNK_WIDTH
		
		for x in range(CHUNK_WIDTH):
			blocks_data[x] = []
			blocks_data[x].resize(CHUNK_HEIGHT)
			var global_x: float = float(world_x_offset + x)
			
			for y in range(CHUNK_HEIGHT):
				blocks_data[x][y] = []
				blocks_data[x][y].resize(CHUNK_WIDTH)
				blocks_data[x][y].fill(BlockRegistry.BlockType.AIR)
				
			for z in range(CHUNK_WIDTH):
				var global_z: float = float(world_z_offset + z)
				var noise_val: float = _noise.get_noise_2d(global_x, global_z)
				
				# Chuẩn hóa giá trị nhiễu về độ cao thực tế của địa hình
				var normalized_height: int = clampi(floori((noise_val + 1.0) * 0.5 * float(CHUNK_HEIGHT - 10)) + 5, 1, CHUNK_HEIGHT - 1)
				
				for y in range(normalized_height + 1):
					var block_type: int = BlockRegistry.BlockType.STONE
					if y == normalized_height:
						block_type = BlockRegistry.BlockType.GRASS
					elif y > normalized_height - 3:
						block_type = BlockRegistry.BlockType.DIRT
						
					blocks_data[x][y][z] = block_type
					
	# Chuyển tiếp dữ liệu thô về Main Thread an toàn để khởi tạo Node và tính toán Mesh
	call_deferred("_finalize_chunk_on_main_thread", c_pos, blocks_data)

func _finalize_chunk_on_main_thread(c_pos: Vector2i, blocks_data: Array) -> void:
	_mutex.lock()
	_chunks_in_progress.erase(c_pos)
	
	# Kiểm tra nếu người chơi đã di chuyển quá xa khỏi vùng hiển thị trong khi Thread đang chạy
	var distance: Vector2i = (c_pos - _current_player_chunk).abs()
	if distance.x > RENDER_DISTANCE or distance.y > RENDER_DISTANCE:
		_mutex.unlock()
		return
		
	if _active_chunks.has(c_pos):
		_mutex.unlock()
		return
	_mutex.unlock()
	
	var new_chunk: Chunk = Chunk.new()
	new_chunk.chunk_position = c_pos
	new_chunk.position = Vector3(float(c_pos.x * CHUNK_WIDTH), 0.0, float(c_pos.y * CHUNK_WIDTH))
	
	add_child(new_chunk)
	new_chunk.set_blocks_data(blocks_data)
	new_chunk.update_mesh(terrain_material)
	
	_mutex.lock()
	_active_chunks[c_pos] = new_chunk
	_mutex.unlock()

func _unload_distant_chunks(keep_chunks: Array[Vector2i]) -> void:
	_mutex.lock()
	var keys: Array = _active_chunks.keys()
	_mutex.unlock()
	
	for c_pos in keys:
		if not keep_chunks.has(c_pos):
			_mutex.lock()
			var chunk_node: Chunk = _active_chunks[c_pos]
			_active_chunks.erase(c_pos)
			_mutex.unlock()
			
			if is_instance_valid(chunk_node):
				chunk_node.queue_free()
 
