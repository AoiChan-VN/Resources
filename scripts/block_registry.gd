extends Node

# Định nghĩa hằng số kiểu Block để tối ưu hóa hiệu năng thay vì sử dụng chuỗi
enum BlockType {
	AIR = 0,
	STONE = 1,
	DIRT = 2,
	GRASS = 3
}

# Cấu trúc lưu trữ dữ liệu thuộc tính của từng loại Block
var _registry: Dictionary = {}

func _ready() -> void:
	_initialize_registry()

# Đăng ký danh sách thuộc tính đồng nhất cho toàn hệ thống
func _initialize_registry() -> void:
	_registry[BlockType.AIR] = {
		"name": "Air",
		"is_solid": false,
		"textures": {}
	}
	_registry[BlockType.STONE] = {
		"name": "Stone",
		"is_solid": true,
		"textures": {
			"all": Vector2i(0, 0)
		}
	}
	_registry[BlockType.DIRT] = {
		"name": "Dirt",
		"is_solid": true,
		"textures": {
			"all": Vector2i(1, 0)
		}
	}
	_registry[BlockType.GRASS] = {
		"name": "Grass",
		"is_solid": true,
		"textures": {
			"top": Vector2i(2, 0),
			"bottom": Vector2i(1, 0),
			"side": Vector2i(3, 0)
		}
	}

# Truy xuất thông tin độ đặc/rỗng của Block để phục vụ giải thuật Face Culling
func is_block_solid(block_id: int) -> bool:
	if not _registry.has(block_id):
		return false
	return _registry[block_id]["is_solid"]

# Truy xuất tọa độ UV Atlas của từng mặt cụ thể dựa trên hướng mặt Block
func get_block_texture_uv(block_id: int, face_direction: Vector3i) -> Vector2i:
	if not _registry.has(block_id):
		return Vector2i(0, 0)
	
	var textures: Dictionary = _registry[block_id]["textures"]
	if textures.is_empty():
		return Vector2i(0, 0)
		
	if textures.has("all"):
		return textures["all"]
		
	if face_direction == Vector3i.UP and textures.has("top"):
		return textures["top"]
	elif face_direction == Vector3i.DOWN and textures.has("bottom"):
		return textures["bottom"]
	elif textures.has("side"):
		return textures["side"]
		
	return Vector2i(0, 0)
 
