extends Control



@onready var output: TextEdit = $ColorRect/MarginContainer/VBoxContainer/output

@onready var compression: Button = $ColorRect/MarginContainer/VBoxContainer/Compression

@onready var compression_mode: OptionButton = $ColorRect/MarginContainer/VBoxContainer/HBoxContainer6/CompressionMode
@onready var exe_path: LineEdit = $ColorRect/MarginContainer/VBoxContainer/HBoxContainer3/exe_path
@onready var save_path: LineEdit = $ColorRect/MarginContainer/VBoxContainer/HBoxContainer4/save_path
@onready var compression_levels: OptionButton = $ColorRect/MarginContainer/VBoxContainer/HBoxContainer/CompressionLevels
@onready var lzma_compression: OptionButton = $ColorRect/MarginContainer/VBoxContainer/HBoxContainer5/LZMACompression
@onready var keep_backup_files: OptionButton = $ColorRect/MarginContainer/VBoxContainer/HBoxContainer2/KeepBackupFiles


@onready var language: OptionButton = $Language
var executable_path := OS.get_executable_path()
var executable_dir := executable_path.get_base_dir()
func _on_compression_pressed() -> void:
	compression.disabled = true
	var upx_path := executable_dir.path_join("upx").path_join("upx.exe")
	if FileAccess.file_exists(exe_path.text):
		if DirAccess.dir_exists_absolute(save_path.text.get_base_dir()):
			if FileAccess.file_exists(upx_path):
				if compression_mode.selected == 0:
					var exe_pa = exe_path.text
					var exe_name = exe_pa.get_file()
					var pck_path := exe_pa.get_base_dir().path_join(exe_name.get_basename()+".pck")
					var output_path := save_path.text
					if FileAccess.file_exists(pck_path):
						var file = FileAccess.open(pck_path,FileAccess.READ)
						var pck_len := file.get_length()
						print("原始长度",pck_len)
						var pck_data := file.get_buffer(pck_len)
						if pck_data:
							if pck_len%8 <= 4:
								for i in range(4-pck_len%8):
									pck_data.append(0x00)
									print("+0")
							else:
								for i in range(8-pck_len%8):
									pck_data.append(0x00)
									print("+0")
								for i in range(4):
									pck_data.append(0x00)
									print("+0")
							pck_len = pck_data.size()
							print("后",pck_len)
							var buff := StreamPeerBuffer.new()
							buff.put_32(pck_len)
							pck_data.append_array(buff.data_array)
							pck_data.append_array(PackedByteArray([0x00,0x00,0x00,0x00]))
							pck_data.append_array(PackedByteArray([0x47,0x44,0x50,0x43]))
							var dir := DirAccess.open(executable_dir)
							if dir:
								dir.make_dir("temp")
								var temp_dir:=executable_dir.path_join("temp")
								var temp_exe_path:= temp_dir.path_join(exe_name)
								if FileAccess.file_exists(temp_exe_path):
									DirAccess.remove_absolute(temp_exe_path)
									
								var arguments := get_argumengts()
								arguments.append("-o")
								arguments.append(temp_exe_path)
								arguments.append(exe_pa)
								await _output("UPX "+str(arguments),"UPX "+str(arguments))
								var ori_text := output.text
								var out_put_arr := []
								await _output("Await UPX ...","等待UPX运行结束 ...")
								var result = OS.execute(upx_path, arguments, out_put_arr, true)
								
								var out_put_text:String = out_put_arr[0]
								out_put_text = out_put_text.replace("\\n","\n")
								await _output(out_put_text,out_put_text)
								if FileAccess.file_exists(temp_exe_path):
									var fi_file = FileAccess.open(temp_exe_path,FileAccess.READ)
									var fi_exe_data = fi_file.get_buffer(fi_file.get_length())
									fi_file.close()
									DirAccess.remove_absolute(temp_exe_path)
									fi_exe_data.append_array(pck_data)
									var last_file = FileAccess.open(output_path,FileAccess.WRITE)
									last_file.store_buffer(fi_exe_data)
									last_file.close()
									await _output("Finished!","完成！")
								
					else:
						await _output("Error: Please ensure that there is a pck file with the same name in the exe directory","错误：请确保exe路径下有同名的pck文件")
			else:
				await _output("Error: No UPX found","错误：未找到UPX")
		else:
			await _output("Error: Save path doesn't exist","错误：保存路径不存在")
			
	else:
		await _output("Error: The .exe doesn't exist","错误：目标exe不存在")
		
	compression.disabled = false

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.is_pressed():
		get_viewport().gui_release_focus()
		
func _output(en:String, zh_cn:String):
	if language.selected == 1:
		output.text += zh_cn
	else:
		output.text += en
	output.text += "\n"
	output.scroll_vertical += 100
	await get_tree().process_frame

func get_argumengts() -> PackedStringArray:
	var argumengts :PackedStringArray= []
	if compression_levels.selected >= 9:
		argumengts.append("--best")
	else:
		argumengts.append("-"+str(compression_levels.selected+1))
	if lzma_compression.selected == 0:
		argumengts.append("--lzma")
		
	if keep_backup_files.selected == 0:
		argumengts.append("-k")
		
		
	return argumengts


				#var file = FileAccess.open(exe_path.text,FileAccess.READ)
					#if file:
						#var exe_data := file.get_buffer(file.get_length())
						#var exe_data_size := exe_data.size()
						#var exe_name = exe_path.text.get_file()
						#file.close()
						#if exe_data[-1] == 0x43 and exe_data[-2] == 0x50 and exe_data[-3] == 0x44 and exe_data[-4] == 0x47:
							#var pck_lenth_byte:PackedByteArray = exe_data.slice(exe_data_size-12,exe_data_size-8)
							#var pck_lenth:int  = pck_lenth_byte.decode_u32(0)
							#if exe_data_size > pck_lenth+12:
								#var pck_data := exe_data.slice(exe_data_size-pck_lenth-12)
								#if pck_data.size() > 4 and pck_data[0]==0x47 and pck_data[1]==0x44 and pck_data[2]==0x50 and pck_data[3]==0x43:
									#await _output("The embedded PCK was successfully cut","内嵌pck切取成功")
									#var no_pck_exe_data := exe_data.slice(0,exe_data_size-pck_lenth-12)
#
									#var dir := DirAccess.open(executable_dir)
									#if dir:
										#dir.make_dir("temp")
										#var temp_dir:=executable_dir.path_join("temp")
										#var temp_exe_path:= temp_dir.path_join("temp12345678123456781234567.exe")
										#var temp_file = FileAccess.open(temp_exe_path,FileAccess.WRITE)
										#if temp_file:
											#temp_file.store_buffer(no_pck_exe_data)
											#temp_file.close()
											#temp_file = null
											#var arguments := get_argumengts()
											#arguments.append("-o")
											#arguments.append(temp_dir.path_join(exe_name))
											#arguments.append(temp_exe_path)
											#await _output("UPX "+str(arguments),"UPX "+str(arguments))
											#var ori_text := output.text
											#var out_put_arr := []
											#await _output("Await UPX ...","等待UPX运行结束 ...")
											#var result = OS.execute(upx_path, arguments, out_put_arr, true)
											#var out_put_text:String = out_put_arr[0]
											#out_put_text = out_put_text.replace("\\n","\n")
											#await _output(out_put_text,out_put_text)
								#else:
									#await _output("Error: Embedded PCK not found","错误：未找到内嵌的pck")


func _on_button_pressed() -> void:
	output.text = ""
