extends Control



@onready var output: TextEdit = $ColorRect/MarginContainer/VBoxContainer/output

@onready var compression: Button = $ColorRect/MarginContainer/VBoxContainer/Compression

@onready var compression_mode: OptionButton = $ColorRect/MarginContainer/VBoxContainer/HBoxContainer6/CompressionMode
@onready var exe_path: LineEdit = $ColorRect/MarginContainer/VBoxContainer/HBoxContainer3/exe_path
@onready var save_path: LineEdit = $ColorRect/MarginContainer/VBoxContainer/HBoxContainer4/save_path
@onready var compression_levels: OptionButton = $ColorRect/MarginContainer/VBoxContainer/HBoxContainer/CompressionLevels
@onready var lzma_compression: OptionButton = $ColorRect/MarginContainer/VBoxContainer/HBoxContainer5/LZMACompression
@onready var keep_backup_files: OptionButton = $ColorRect/MarginContainer/VBoxContainer/HBoxContainer2/KeepBackupFiles

@onready var upx_win: Window = $upx_win




@onready var language: OptionButton = $Language
var executable_path := OS.get_executable_path()
var executable_dir := executable_path.get_base_dir()
func _on_compression_pressed() -> void:
	compression.disabled = true
	var upx_path := executable_dir.path_join("upx").path_join("upx.exe")
	if FileAccess.file_exists(exe_path.text):
		if DirAccess.dir_exists_absolute(save_path.text.get_base_dir()):
			if FileAccess.file_exists(upx_path):
				if compression_mode.selected == 0: #model:exe of Godot
					var exe_pa := exe_path.text
					var exe_name = exe_pa.get_file()
					var pck_path := exe_pa.get_base_dir().path_join(exe_name.get_basename()+".pck")
					var output_path := save_path.text
					var pck_data:PackedByteArray
					var pck_data_readied:bool
					var aim_exe_path := exe_pa
					
					
					var exe_file = FileAccess.open(exe_path.text,FileAccess.READ)
					
					if exe_file:
						var exe_data :PackedByteArray= exe_file.get_buffer(exe_file.get_length())
						var exe_data_size := exe_data.size()

						exe_file.close()
						if exe_data.size() <= 12:
							await _output("Error: Can't get data from the exe or the exe is empty","错误：无法读取exe的数据或exe为空")
							
						elif exe_data[-1] == 0x43 and exe_data[-2] == 0x50 and exe_data[-3] == 0x44 and exe_data[-4] == 0x47:
							
							
							await _output("Error: Don't compress a exe with embedded PCK","错误：请不要压缩内嵌pck的exe")
							await _output("Please do not check \"Embed PCK\" when exporting, and ensure that the PCK file corresponding to the EXE exists in the directory during compression.","请在导出时不要勾选“内嵌pck”，并在压缩时确保目录下存在该exe的pck文件")
							compression.disabled = false
							return
							
							var pck_lenth_byte:PackedByteArray = exe_data.slice(exe_data_size-12,exe_data_size-8)
							var pck_lenth:int  = pck_lenth_byte.decode_u32(0)
							if exe_data_size > pck_lenth+12:
								pck_data = exe_data.slice(exe_data_size-pck_lenth-12)
								if pck_data.size() > 12 and pck_data[0]==0x47 and pck_data[1]==0x44 and pck_data[2]==0x50 and pck_data[3]==0x43:
									await _output("The embedded PCK was successfully cut","内嵌pck切取成功")
									var no_pck_exe_data := exe_data.slice(0,exe_data_size-pck_lenth-12)

									var dir := DirAccess.open(executable_dir)
									if dir:
										dir.make_dir("temp")
										var temp_dir:=executable_dir.path_join("temp")
										var temp_exe_path:= temp_dir.path_join(exe_name.get_basename()+"-without pck"+".exe")
										var temp_file = FileAccess.open(temp_exe_path,FileAccess.WRITE)
										if temp_file:
											temp_file.store_buffer(no_pck_exe_data)
											temp_file.close()
											
											aim_exe_path = temp_exe_path
											pck_data_readied = true
											
								else:
									await _output("Error:Can't analysis the embedded PCK ","错误：无法解析内嵌的pck")
							
							else:
								await _output("Error: The exe file may be damaged (Length data of pck is incorrect) ","错误：exe文件疑似损坏了（pck长度数据错误）")
						
						
						elif FileAccess.file_exists(pck_path):
							var file = FileAccess.open(pck_path,FileAccess.READ)
							var pck_len := file.get_length()

							pck_data = file.get_buffer(pck_len)
							if pck_data:
								if pck_len%8 <= 4:
									for i in range(4-pck_len%8):
										pck_data.append(0x00)
										
								else:
									for i in range(8-pck_len%8):
										pck_data.append(0x00)
										
									for i in range(4):
										pck_data.append(0x00)
										
								pck_len = pck_data.size()

								var buff := StreamPeerBuffer.new()
								buff.put_32(pck_len)
								pck_data.append_array(buff.data_array) 
								pck_data.append_array(PackedByteArray([0x00,0x00,0x00,0x00]))
								pck_data.append_array(PackedByteArray([0x47,0x44,0x50,0x43]))
								pck_data_readied = true
								
							else:
								await _output("Error: Can't get data from the pck file","错误：无法从pck文件中读取到数据")
						else:
							await _output("Error: Please ensure that there is a pck file with the same name in the exe directory","错误：请确保exe路径下有同名的pck文件")
						
						#run UPX
						if pck_data_readied:
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
								arguments.append(aim_exe_path)
								

								await _output("UPX "+str(arguments),"UPX "+str(arguments))
								await _output("Await UPX ...","等待UPX运行结束 ...")
								
								var thread := Thread.new()
								var out_arr:Array

								thread.start(func():
									OS.execute(upx_path,arguments,out_arr,true)
									call_deferred(&"thread_end")
									)
								#var pro_id := OS.create_process(upx_path,arguments)
								#if pro_id == -1:
									#await _output("Error: Can't run UPX","错误：无法运行UPX")

								upx_win.show_win()
									
								await upx_win.thread_finished
								
								upx_win.hide_win()

								
								#move and append pck_data

								await _output(str(out_arr),str(out_arr))
								
								if FileAccess.file_exists(temp_exe_path):
									var fi_file = FileAccess.open(temp_exe_path,FileAccess.READ)
									var fi_exe_data = fi_file.get_buffer(fi_file.get_length())
									fi_file.close()
									DirAccess.remove_absolute(temp_exe_path)
									fi_exe_data.append_array(pck_data)
									var final_file = FileAccess.open(output_path,FileAccess.WRITE)
									if final_file:
										final_file.store_buffer(fi_exe_data)
										final_file.close()
										await _output("Finished!","完成！")
									else:
										await _output("Failed to create the exe file in the target location.","错误：无法在目标位置创建exe文件")
								else:
									await _output("Error: Can't find the result of UPX","错误：未能找到UPX的生成结果")
					
				
					
					
								
								
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
		
	argumengts.append("--force")	
	
	return argumengts


				


func _on_button_pressed() -> void:
	output.text = ""

func thread_end():
	upx_win.thread_finished.emit()
