use std::{
	num::{NonZero, NonZeroU8},
	ops::Sub,
};

use godot::prelude::*;
use serde::{Deserialize, Serialize};

/// Inputs with attack overweighs Inputs with no attack.
#[derive(Debug, PartialEq, Eq, Clone, Copy, GodotClass)]
#[class(no_init)]
pub struct FgInput {
	pub movement: i8,
	pub attack_press: bool,
	pub special_press: bool,
}

#[godot_api]
impl FgInput {
	#[func]
	pub fn gd_new(movement: i8, attack_press: bool, special_press: bool) -> Gd<Self> {
		Gd::from_object(Self::new(movement, attack_press, special_press))
	}

	pub const fn new(movement: i8, attack_press: bool, special_press: bool) -> Self {
		FgInput {
			movement,
			attack_press,
			special_press,
		}
	}

	pub const fn to_attack_buffer(self) -> Option<ActionBuffer> {
		ActionBuffer::new(self.movement, self.attack_press)
	}

	pub const fn to_special_buffer(self) -> Option<ActionBuffer> {
		ActionBuffer::new(self.movement, self.special_press)
	}
}

#[derive(Debug, PartialEq, Eq, Clone, Copy, Serialize, Deserialize)]
pub struct ActionBuffer {
	pub movement: i8,
	pub buff_time: NonZeroU8,
}

impl ActionBuffer {
	// n - 1 is buffer length
	const BUFFER_TIME: NonZeroU8 = NonZero::new(4).unwrap();

	pub const fn new(movement: i8, attack_press: bool) -> Option<Self> {
		if attack_press {
			Some(ActionBuffer {
				movement,
				buff_time: Self::BUFFER_TIME,
			})
		} else {
			None
		}
	}

	pub fn update_buffer(self) -> Option<Self> {
		let time = self.buff_time.get().sub(1).try_into().ok()?;

		Some(ActionBuffer {
			buff_time: time,
			..self
		})
	}

	pub const fn compare(old: Option<Self>, new: Option<Self>) -> Option<Self> {
		match new {
			Some(_) => new,
			None => old,
		}
	}
}

#[cfg(test)]
mod test {
	use std::num::NonZero;

	use super::ActionBuffer;

	#[test]
	fn update_buffer() {
		let input = ActionBuffer::new(1, true).unwrap();

		assert_eq!(NonZero::new(4).unwrap(), input.buff_time);
		let input = input.update_buffer().unwrap();
		assert_eq!(NonZero::new(3).unwrap(), input.buff_time);
		let input = input.update_buffer().unwrap();
		assert_eq!(NonZero::new(2).unwrap(), input.buff_time);
		let input = input.update_buffer().unwrap();
		assert_eq!(NonZero::new(1).unwrap(), input.buff_time);
		let input = input.update_buffer();
		assert_eq!(None, input);
	}

	#[test]
	fn compare() {
		let input1 = ActionBuffer::new(0, false);
		let input2 = ActionBuffer::new(1, false);
		let input3 = ActionBuffer::new(-1, false);
		let input4 = Option::<ActionBuffer>::None;
		let input5 = ActionBuffer::new(-1, true);
		let input6 = ActionBuffer::new(1, true);
		let input7 = ActionBuffer::new(0, false);

		assert_eq!(ActionBuffer::compare(input1, input2), input2);
		assert_eq!(ActionBuffer::compare(input2, input3), input3);
		assert_eq!(ActionBuffer::compare(input2, input1), input1);
		assert_eq!(ActionBuffer::compare(input2, input4), input2);

		assert_eq!(ActionBuffer::compare(input5, input1), input5);

		assert_ne!(ActionBuffer::compare(input5, input6), input5);
		assert_eq!(ActionBuffer::compare(input5, input6), input6);
		assert_eq!(ActionBuffer::compare(input6, input7), input6);
	}
}
