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

const uri: String = "https://github.com/Kitware/CMake/releases/tag/v3.19.7"

func _ready():
	get_close_button().connect("pressed", self, "_abort")
	_abort_btn.connect("pressed", self, "_abort")
	_download_btn.connect("pressed", self, "_download")
	_continue_btn.connect("pressed", self, "_continue")
	popup_centered()
	
func _abort():
	get_tree().quit()

func _download():
	OS.shell_open(uri)

func _continue():
	get_parent()._continue()
