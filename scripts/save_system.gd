extends Node
class_name SaveSystem

# Đường dẫn an toàn lưu trữ dữ liệu ứng dụng trên hệ điều hành Android (Sandboxed Storage)
const SAVE_PATH: String = "user://world_save.dat"
# Mã nhận diện định dạng file (Magic Number) nhằm xác thực tính toàn vẹn dữ liệu khi Load
const FILE_MAGIC: int = 0x4D433344 # Ký tự ASCII đại diện cho "MC3D"

# Cấu trúc lưu trữ dữ liệu thô của thế giới để ghi xuống file nhị phân
# Định dạng truyền vào: Dictionary { Vector2i(x, z): Array(3D Blocks Data) }
static func save_world(active_chunks: Dictionary) -> bool:
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		var err: Error = FileAccess.get_open_error()
		push_error("[SaveSystem] Không thể mở file để ghi dữ liệu. Mã lỗi: %d" % err)
		return false
		
	# 1. Ghi mã nhận diện đầu file (Header Validation)
	file.store_32(FILE_MAGIC)
	
	# 2. Ghi số lượng Chunk thực tế sẽ được lưu trữ
	var chunk_count: int = active_chunks.size()
	file.store_32(chunk_count)
	
	# 3. Duyệt qua từng Chunk và nhị phân hóa mảng dữ liệu khối
	for chunk_pos in active_chunks.keys():
		var chunk_node: Chunk = active_chunks[chunk_pos] as Chunk
		if chunk_node == null:
			continue
			
		# Ghi tọa độ của Chunk (X, Z) dưới dạng số nguyên 32-bit
		file.store_32(chunk_pos.x)
		file.store_32(chunk_pos.y)
		
		# Ghi tuần tự mảng dữ liệu 3 chiều [X][Y][Z] của Chunk vào luồng nhị phân
		var chunk_width: int = WorldManager.CHUNK_WIDTH
		var chunk_height: int = WorldManager.CHUNK_HEIGHT
		
		for x in range(chunk_width):
			for y in range(chunk_height):
				for z in range(chunk_width):
					var block_id: int = chunk_node._blocks[x][y][z]
					# Sử dụng store_8 (1 byte) thay vì store_32 (4 bytes) vì ID Block nhỏ hơn 255
					# Tối ưu hóa Mobile: Giảm ngay 75% dung lượng file lưu trữ của mảng Block
					file.store_8(block_id)
					
	file.close()
	return true

# Hàm nạp dữ liệu từ bộ nhớ di động, giải mã nhị phân và tái cấu trúc lại mảng
static func load_world() -> Dictionary:
	var loaded_data: Dictionary = {}
	
	if not FileAccess.file_exists(SAVE_PATH):
		return loaded_data # Trả về Dictionary rỗng nếu không tìm thấy file Save (Chạy thế giới mới)
		
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		var err: Error = FileAccess.get_open_error()
		push_error("[SaveSystem] Không thể mở file để đọc dữ liệu. Mã lỗi: %d" % err)
		return loaded_data
		
	# 1. Kiểm tra tính hợp lệ của file thông qua Header Magic Number
	var magic: int = file.get_32()
	if magic != FILE_MAGIC:
		file.close()
		push_error("[SaveSystem] Lỗi: File Save bị hỏng cấu trúc hoặc không đúng định dạng nhị phân của MC3D.")
		return loaded_data
		
	# 2. Đọc số lượng Chunk được lưu trong file
	var chunk_count: int = file.get_32()
	var chunk_width: int = WorldManager.CHUNK_WIDTH
	var chunk_height: int = WorldManager.CHUNK_HEIGHT
	
	# 3. Giải mã luồng dữ liệu nhị phân quay ngược lại mảng 3 chiều
	for i in range(chunk_count):
		# Đọc tọa độ Chunk
		var cx: int = file.get_32()
		var cz: int = file.get_32()
		var chunk_pos: Vector2i = Vector2i(cx, cz)
		
		# Khởi tạo ma trận trống để nạp dữ liệu khối vào
		var blocks_data: Array = []
		blocks_data.resize(chunk_width)
		for x in range(chunk_width):
			blocks_data[x] = []
			blocks_data[x].resize(chunk_height)
			for y in range(chunk_height):
				blocks_data[x][y] = []
				blocks_data[x][y].resize(chunk_width)
				
		# Đọc tuần tự dữ liệu từng byte block gán vào ma trận
		for x in range(chunk_width):
			for y in range(chunk_height):
				for z in range(chunk_width):
					var block_id: int = file.get_8()
					blocks_data[x][y][z] = block_id
					
		loaded_data[chunk_pos] = blocks_data
		
	file.close()
	return loaded_data
 
