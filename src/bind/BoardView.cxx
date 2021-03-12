/*
 *  BoardView.cxx
 *  Copyright 2021 ItJustWorksTM
 *
 *  Licensed under the Apache License, Version 2.0 (the "License");
 *  you may not use this file except in compliance with the License.
 *  You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 *
 */

#include "bind/BoardView.hxx"

using namespace godot;

void BoardView::_init() {}

void BoardView::_register_methods() {
    register_signal<BoardView>("invalidated", Dictionary{});
    register_method("read_analog_pin", &BoardView::read_analog_pin);
    register_method("read_digital_pin", &BoardView::read_digital_pin);
    register_method("write_analog_pin", &BoardView::write_analog_pin);
    register_method("write_digital_pin", &BoardView::write_digital_pin);
}

smce::BoardView BoardView::native() { return view; }

const smce::BoardConfig& BoardView::board_config() const { return config; }

int BoardView::read_analog_pin(int pin) {
    return view.pins[pin].analog().read();
}

bool BoardView::read_digital_pin(int pin) {
    return view.pins[pin].digital().read();
}

void BoardView::write_analog_pin(int pin, int value) {
    view.pins[pin].analog().write(value);
}

void BoardView::write_digital_pin(int pin, bool value) {
    view.pins[pin].digital().write(value);
}
