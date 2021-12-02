#
#  Copyright 2021 ItJustWorksTM
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.
#

extends WindowDialog

onready var _abort_btn = $AbortButton
onready var _download_btn = $DownloadButton
onready var _continue_btn = $ContinueButton
onready var _http = $HTTPRequest
onready var _progress_bar = $DownloadBar
onready var _unpacking_bar = $UnpackBar

var unpacking_in_progress = false
var target_package: String
var target_exec: String
var target_dir: String
var target_file: String
var user_dir: String
var console_output = []

const target_url: String = "https://github.com/Kitware/CMake/releases/download/v3.21.0/"
const cmake_os_params = {
	"OSX": ["cmake-3.21.0-macos-universal.tar.gz", "/cmake-3.21.0-macos-universal", "/cmake-3.21.0-macos-universal/CMake.app/Contents/bin/", "cmake"],
	"Windows": ["cmake-3.21.0-windows-x86_64.zip", "/cmake-3.21.0-windows-x86_64" , "/cmake-3.21.0-windows-x86_64/bin/", "cmake.exe"],
	"X11": ["cmake-3.21.0-linux-x86_64.tar.gz", "/cmake-3.21.0-linux-x86_64", "/cmake-3.21.0-linux-x86_64/bin/cmake", "cmake"],
}

func _ready():
	get_close_button().connect("pressed", self, "_abort")
	_abort_btn.connect("pressed", self, "_abort")
	_download_btn.connect("pressed", self, "_download")
	_continue_btn.connect("pressed", self, "_continue")
	
	# Initialize package parameters based on the operating system in use
	var cmake_params = cmake_os_params.get(OS.get_name())
	target_package = cmake_params[0]
	target_dir = OS.get_user_data_dir() + cmake_params[1]
	target_exec = target_dir + cmake_params[2]
	target_file = cmake_params[3]
	popup_centered()
	if Directory.new().dir_exists(target_exec) && File.new().file_exists(target_exec + target_file):
		_continue_btn.emit_signal("pressed")
	
func _abort():
	get_tree().quit()

func _continue():
	if _continue_btn.text == "Restart":
		_abort()
	get_parent()._continue()

func _download():
	_progress_bar.show()
	_download_btn.disabled = true
	_continue_btn.disabled = true
	
	print("Target environment:\nPackage: %s\nDirectory: %s\nExecutable: %s" % [target_package, target_dir, target_exec])
	
	var package_path = OS.get_user_data_dir() + '/' + target_package 
	# Check for local CMake. If not, download package
	if !File.new().file_exists(target_exec + target_file):
		if !File.new().file_exists(package_path):
			var remote_package_size = yield(get_remote_package_size(target_url + target_package), "completed")
			if !remote_package_size:
				print("Couldn't reach the remote CMake package.")
				return null
			
			print("Downloading CMake package...")
			var download_status = yield(download_handler(target_url + target_package, remote_package_size), "completed")
			if !download_status:
				print("Couldn't download the CMake package.")
				return null
			print("Package downloaded.")
		
		_progress_bar.value = 100
		if !Directory.new().dir_exists(target_exec):
			print("Unpacking...")
			var unzip_thread = unpack(package_path, target_dir)
		else:
			_finish()
	else:
		print("Environment is configured correctly!")

# Retrieve the size of the package to be downloaded. Used for synchronizing the
# progress bar with the HTTP client
func get_remote_package_size(url):
	_http.request(url, [], false, HTTPClient.METHOD_HEAD)
	var response = yield(_http, "request_completed")
	var response_code = response[1]
	if response_code == 200:
		var headers = response[2]
		var remote_package_size = int(headers[1].split(": ")[1])
		return remote_package_size
	return null

# Package download handler responsible for pulling the compatible version
# of the CMake package.
func download_handler(url, package_size):
	var target_file = OS.get_user_data_dir() + '/' + target_package
	_http.download_file = target_file + '.tmp'
	# Begin downloading the package
	if !_http.request(target_url + target_package):
		var progress_thread = Thread.new()
		progress_thread.start(self, "progress_thread_handler", package_size)
		yield(_http, "request_completed")
		Directory.new().copy(_http.download_file, target_file)
		Directory.new().remove(_http.download_file)
		return true
	return null

# Function loop for handling the progress bar update thread
func progress_thread_handler(package_size):
	while _progress_bar.value < 100:
		_progress_bar.value = round(float(_http.get_downloaded_bytes()) / package_size * 100)
		yield(get_tree().create_timer(0.05), "timeout")
	
# Helper function for instantiating package unpacking and the progress bar update
# thread	
func unpack(file, dest_dir):
	if !File.new().file_exists(file):
		return null
	var unpacking_monitor_thread = Thread.new()
	var unzip_thread = Thread.new()
	unpacking_in_progress = true
	unpacking_monitor_thread.start(self, "unpacking_thread_handler", true)
	unzip_thread.start(self, "unzip_exec", [file, dest_dir])
	unpacking_monitor_thread.wait_to_finish()
	return unzip_thread

# Function responsible for initiating the shell-based, OS-specific package
# unpacking process thread
func unzip_exec(data):
	_unpacking_bar.show()
	var file = data[0]
	var dest_dir = data[1]
	match OS.get_name():
		"OSX":
			OS.execute("tar", ["-C", dest_dir, "-zxvf", file], true, console_output) == 0
		"Windows":
			OS.execute("powershell.exe", ["Expand-Archive", "-Path", file, "-DestinationPath", dest_dir], true, console_output) == 0
		"X11":
			OS.execute("tar", ["-C", dest_dir, "-zxvf", file], true, console_output) == 0
	unpacking_in_progress = false

# Progress bar update loop for the unpacking process. Approxiamates the progress
# rather than tracking the shell for simplicity's sake.
func unpacking_thread_handler(data):
	var i = 0
	var timing = 1
	while i < 100:
		if unpacking_in_progress == false || i >= 95:
			timing = 0.1
			i += 1
		else:
			i += 0.5
		_unpacking_bar.value = i
		yield(get_tree().create_timer(timing), "timeout")
	_unpacking_bar.value = 100
	_finish()

# Finalzie the path linking. Valid ONLY for Windows-based environments and uses
# global PATH modification. Must be changed to something less extreme.
func _finish():
	if File.new().file_exists(target_exec + target_file):
		var old_path = [] 
		OS.execute("powershell.exe",["(", "Get-ItemProperty", "-Path", "'Registry::HKEY_LOCAL_MACHINE\\System\\CurrentControlSet\\Control\\Session Manager\\Environment'", "-Name", "PATH", ").Path"], true, old_path)
		var new_path = old_path[0] + ";" + target_exec
		new_path = new_path.split('\n')
		var p = ""
		for el in new_path:
			p = p + el
			
		print(p)
		OS.execute("powershell.exe",["Set-ItemProperty", "-Path", "'Registry::HKEY_LOCAL_MACHINE\\System\\CurrentControlSet\\Control\\Session Manager\\Environment'", "-Name", "PATH", "-Value", "'" + p + "'"], true)
		_continue_btn.disabled = false
		_abort_btn.disabled = true
		_continue_btn.text = "Restart"
		return true
	print("Error! No CMake found at PATH")
	return null
