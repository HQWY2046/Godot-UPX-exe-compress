extends Node
var set_dic:Dictionary
var executable_dir := OS.get_executable_path().get_base_dir()

func _ready() -> void:
	set_dic = load_set()
func load_set() -> Dictionary:
	if DirAccess.dir_exists_absolute(executable_dir.path_join("settings")):
		var file_path := executable_dir.path_join("settings").path_join(".set")
		if FileAccess.file_exists(file_path):
			var cfg := ConfigFile.new()
			if cfg.load(file_path) == OK:
				return cfg.get_value("set","set",{})
	return {}


func save_set() -> void:
	var settings_dir_path := executable_dir.path_join("settings")
	if not DirAccess.dir_exists_absolute(settings_dir_path):
		var dir := DirAccess.open(executable_dir)
		if dir:
			var dir_error := dir.make_dir("settings")
			if dir_error != OK:
				return
	var file_path := settings_dir_path.path_join(".set")
	var cfg := ConfigFile.new()
	cfg.set_value("set", "set", set_dic)
	cfg.save(file_path)

		
	
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		if set_dic:
			save_set()
		get_tree().quit()
