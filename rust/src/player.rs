use serde::{Deserialize, Serialize};

use crate::{
	framedata::*,
	input::{ActionBuffer, FgInput},
	simul::Match,
};

#[derive(Debug, Clone)]
#[derive(Serialize, Deserialize)]
pub struct Player {
	pub position: i16,
	pub wins: u8,
	state: PlayerState,
	normal_buff: Option<ActionBuffer>,
	special_buff: Option<ActionBuffer>,
	dash_buff: Option<ActionBuffer>,
	fdash_timer: u8,
	bdash_timer: u8,
	movement: i8,
	bot: bool,
}

impl Player {
	const PLAYER_DASH_TIME: u8 = 10;
	const BOT_DASH_TIME: u8 = 3;

	#[inline]
	pub const fn new(start_pos: i16, bot: bool) -> Self {
		Player {
			position: start_pos,
			wins: 0,
			state: PlayerState::Idle(0),
			normal_buff: None,
			special_buff: None,
			dash_buff: None,
			fdash_timer: 0,
			bdash_timer: 0,
			movement: 0,
			bot,
		}
	}

	#[inline]
	pub const fn reset(&mut self, start_pos: i16) {
		*self = Player {
			wins: self.wins,
			..Player::new(start_pos, self.bot)
		};
	}

	pub const fn set_input(&mut self, input: FgInput) {
		self.movement = input.movement;
		self.normal_buff = ActionBuffer::compare(self.normal_buff, input.to_buffer());

		// Dash
		match input.movement_press {
			1.. if self.fdash_timer > 0 => {
				self.dash_buff = ActionBuffer::new(1, true);
				self.reset_dash_timer();
			}
			1.. => {
				self.reset_dash_timer();
				self.fdash_timer = self.dash_time();
			}
			..=-1 if self.bdash_timer > 0 => {
				self.dash_buff = ActionBuffer::new(-1, true);
				self.reset_dash_timer();
			}
			..=-1 => {
				self.reset_dash_timer();
				self.bdash_timer = self.dash_time();
			}
			_ => {
				self.fdash_timer = self.fdash_timer.saturating_sub(1);
				self.bdash_timer = self.bdash_timer.saturating_sub(1);
			}
		}
	}

	#[inline]
	pub fn update_buffer(&mut self) {
		self.normal_buff = self.normal_buff.and_then(|input| input.update_buffer());
		self.special_buff = self.special_buff.and_then(|input| input.update_buffer());
		self.dash_buff = self.dash_buff.and_then(|input| input.update_buffer());
	}

	#[inline]
	pub fn update_state(&mut self) {
		self.update_stance();
		self.update_action();
	}

	fn update_stance(&mut self) {
		self.state = match self.state {
			PlayerState::Idle(frame) => match self.movement {
				0 => PlayerState::Idle(frame + 1),
				1.. => PlayerState::FWalk(0),
				_ => PlayerState::BWalk(0),
			},
			PlayerState::FWalk(frame) => match self.movement {
				0 => PlayerState::Idle(0),
				1.. => PlayerState::FWalk(frame + 1),
				_ => PlayerState::BWalk(0),
			},
			PlayerState::BWalk(frame) => match self.movement {
				0 => PlayerState::Idle(0),
				1.. => PlayerState::FWalk(0),
				_ => PlayerState::BWalk(frame + 1),
			},
			PlayerState::FDash(frame) => PlayerState::FDash(frame + 1),
			PlayerState::BDash(frame) => PlayerState::BDash(frame + 1),
			PlayerState::NNormal(frame, hit) => PlayerState::NNormal(frame + 1, hit),
			PlayerState::MNormal(frame, hit) => PlayerState::MNormal(frame + 1, hit),
			PlayerState::NSpecial(frame, hit) => PlayerState::NSpecial(frame + 1, hit),
			PlayerState::MSpecial(frame, hit) => PlayerState::MSpecial(frame + 1, hit),
			PlayerState::Dead(_) => PlayerState::Dead(true),
		}
	}

	fn update_action(&mut self) {
		self.state = match self.state {
			PlayerState::Idle(_) | PlayerState::FWalk(_) | PlayerState::BWalk(_) => {
				if let Some(state) = self.which_action() {
					self.reset_input();
					state
				} else {
					self.state
				}
			}
			PlayerState::NNormal(_, hit) | PlayerState::MNormal(_, hit) => {
				match self.normal_buff.is_some() {
					true if hit && self.update_move().data.cancel => {
						self.reset_input();
						PlayerState::NSpecial(0, false)
					}
					_ => self.state,
				}
			}
			_ => self.state,
		}
	}

	pub fn update_move(&mut self) -> &'static MoveData {
		match self.state {
			PlayerState::Idle(frame) => {
				if let Some(data) = idle_data(frame) {
					data
				} else {
					self.state = PlayerState::Idle(0);
					idle_data(0).unwrap()
				}
			}
			PlayerState::FWalk(frame) => {
				if let Some(data) = fwalk_data(frame) {
					data
				} else {
					self.state = PlayerState::FWalk(0);
					fwalk_data(0).unwrap()
				}
			}
			PlayerState::BWalk(frame) => {
				if let Some(data) = bwalk_data(frame) {
					data
				} else {
					self.state = PlayerState::BWalk(0);
					bwalk_data(0).unwrap()
				}
			}
			PlayerState::FDash(frame) => {
				if let Some(data) = fdash_data(frame) {
					data
				} else {
					self.state = PlayerState::Idle(0);
					idle_data(0).unwrap()
				}
			}
			PlayerState::BDash(frame) => {
				if let Some(data) = bdash_data(frame) {
					data
				} else {
					self.state = PlayerState::Idle(0);
					idle_data(0).unwrap()
				}
			}
			PlayerState::NNormal(frame, _) => {
				if let Some(data) = nnormal_data(frame) {
					data
				} else {
					self.state = PlayerState::Idle(0);
					idle_data(0).unwrap()
				}
			}
			PlayerState::MNormal(frame, _) => {
				if let Some(data) = mnormal_data(frame) {
					data
				} else {
					self.state = PlayerState::Idle(0);
					idle_data(0).unwrap()
				}
			}
			PlayerState::NSpecial(frame, _) => {
				if let Some(data) = nspecial_data(frame) {
					data
				} else {
					self.state = PlayerState::Idle(0);
					idle_data(0).unwrap()
				}
			}
			PlayerState::MSpecial(frame, _) => {
				if let Some(data) = mspecial_data(frame) {
					data
				} else {
					self.state = PlayerState::Idle(0);
					idle_data(0).unwrap()
				}
			}
			PlayerState::Dead(_) => dead_data(),
		}
	}

	#[inline]
	pub fn move_position(&mut self, movement: i16) {
		self.position = (self.position + movement).clamp(0, Match::STAGE_LEN);
	}

	#[inline]
	pub const fn reset_input(&mut self) {
		self.normal_buff = None;
		self.special_buff = None;
	}

	#[inline]
	pub const fn reset_dash_timer(&mut self) {
		self.fdash_timer = 0;
		self.bdash_timer = 0;
	}

	pub fn get_move(&self) -> &'static MoveData {
		match self.state {
			PlayerState::Idle(frame) => idle_data(frame).unwrap(),
			PlayerState::FWalk(frame) => fwalk_data(frame).unwrap(),
			PlayerState::BWalk(frame) => bwalk_data(frame).unwrap(),
			PlayerState::FDash(frame) => fdash_data(frame).unwrap(),
			PlayerState::BDash(frame) => bdash_data(frame).unwrap(),
			PlayerState::NNormal(frame, _) => nnormal_data(frame).unwrap(),
			PlayerState::MNormal(frame, _) => mnormal_data(frame).unwrap(),
			PlayerState::NSpecial(frame, _) => nspecial_data(frame).unwrap(),
			PlayerState::MSpecial(frame, _) => mspecial_data(frame).unwrap(),
			PlayerState::Dead(_) => dead_data(),
		}
	}

	pub fn get_attacked(&mut self) {
		self.state = PlayerState::Dead(false);
	}

	#[inline]
	pub fn can_attack(&self) -> bool {
		matches!(
			self.state,
			PlayerState::Idle(_) | PlayerState::BWalk(_) | PlayerState::FWalk(_)
		)
	}

	#[inline]
	pub const fn recovery_punishable(&self) -> u8 {
		match self.state {
			PlayerState::NNormal(frame, _) => move_length(&NNORMAL_DATA) - frame - 1,
			PlayerState::MNormal(frame, _) => move_length(&MNORMAL_DATA) - frame - 1,
			PlayerState::NSpecial(frame, _) => move_length(&NSPECIAL_DATA) - frame - 1,
			PlayerState::MSpecial(frame, _) => move_length(&MSPECIAL_DATA) - frame - 1,
			PlayerState::FDash(frame) => move_length(&FDASH_DATA) - frame - 1,
			_ => 0,
		}
	}

	#[inline]
	pub const fn recovery(&self) -> u8 {
		match self.state {
			PlayerState::Idle(_) => 0,
			PlayerState::FWalk(_) => 0,
			PlayerState::BWalk(_) => 0,
			PlayerState::FDash(frame) => move_length(&FDASH_DATA) - frame - 1,
			PlayerState::BDash(frame) => move_length(&BDASH_DATA) - frame - 1,
			PlayerState::NNormal(frame, _) => move_length(&NNORMAL_DATA) - frame - 1,
			PlayerState::MNormal(frame, _) => move_length(&MNORMAL_DATA) - frame - 1,
			PlayerState::NSpecial(frame, _) => move_length(&NSPECIAL_DATA) - frame - 1,
			PlayerState::MSpecial(frame, _) => move_length(&MSPECIAL_DATA) - frame - 1,
			PlayerState::Dead(_) => 0,
		}
	}

	pub fn buff_time(&self) -> u8 {
		match self.normal_buff {
			Some(input) => input.buff_time.get(),
			None => 0,
		}
	}

	#[inline]
	pub const fn is_dead(&self) -> bool {
		matches!(self.state, PlayerState::Dead(_))
	}

	#[inline]
	pub const fn newly_dead(&self) -> bool {
		matches!(self.state, PlayerState::Dead(false))
	}

	#[inline]
	pub const fn set_hit(&mut self) {
		self.state = match self.state {
			PlayerState::NNormal(frame, _) => PlayerState::NNormal(frame, true),
			PlayerState::MNormal(frame, _) => PlayerState::MNormal(frame, true),
			PlayerState::NSpecial(frame, _) => PlayerState::NSpecial(frame, true),
			PlayerState::MSpecial(frame, _) => PlayerState::MSpecial(frame, true),
			_ => self.state,
		}
	}

	#[inline]
	pub const fn get_hit(&self) -> bool {
		match self.state {
			PlayerState::NNormal(_, hit) => hit,
			PlayerState::MNormal(_, hit) => hit,
			PlayerState::NSpecial(_, hit) => hit,
			PlayerState::MSpecial(_, hit) => hit,
			_ => false,
		}
	}

	#[inline]
	pub const fn get_audio(&self) -> Option<&'static str> {
		match self.state {
			PlayerState::FDash(0) => Some("fdash"),
			PlayerState::BDash(0) => Some("bdash"),
			PlayerState::NNormal(0, _) => Some("nnormal"),
			PlayerState::MNormal(0, _) => Some("mnormal"),
			PlayerState::NSpecial(0, _) => Some("nspecial"),
			PlayerState::MSpecial(0, _) => Some("mspecial"),
			PlayerState::Dead(false) => Some("ender_hit"),
			_ => None,
		}
	}

	#[inline]
	pub fn state_int(&self) -> i64 {
		self.state.into()
	}

	#[inline]
	pub fn state_len(&self) -> i64 {
		self.state.state_len() as i64
	}

	#[inline]
	const fn which_action(&self) -> Option<PlayerState> {
		match self.special_buff {
			Some(buffer) => Some(match buffer.movement {
				0 => PlayerState::NSpecial(0, false),
				_ => PlayerState::MSpecial(0, false),
			}),
			None => match self.normal_buff {
				Some(buffer) => Some(match buffer.movement {
					0 => PlayerState::NNormal(0, false),
					_ => PlayerState::MNormal(0, false),
				}),
				None => match self.dash_buff {
					Some(buffer) => Some(match buffer.movement {
						1.. => PlayerState::FDash(0),
						_ => PlayerState::BDash(0),
					}),
					None => None,
				},
			},
		}
	}

	#[inline]
	const fn dash_time(&self) -> u8 {
		match self.bot {
			true => Self::BOT_DASH_TIME,
			false => Self::PLAYER_DASH_TIME,
		}
	}
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
#[derive(Serialize, Deserialize)]
pub enum PlayerState {
	Idle(u8),
	FWalk(u8),
	BWalk(u8),
	FDash(u8),
	BDash(u8),
	NNormal(u8, bool),
	MNormal(u8, bool),
	NSpecial(u8, bool),
	MSpecial(u8, bool),
	Dead(bool),
}

impl PlayerState {
	#[inline]
	fn state_len(self) -> u8 {
		match self {
			PlayerState::Idle(f) => f,
			PlayerState::FWalk(f) => f,
			PlayerState::BWalk(f) => f,
			PlayerState::FDash(f) => f,
			PlayerState::BDash(f) => f,
			PlayerState::NNormal(f, _) => f,
			PlayerState::MNormal(f, _) => f,
			PlayerState::NSpecial(f, _) => f,
			PlayerState::MSpecial(f, _) => f,
			PlayerState::Dead(_) => 0,
		}
	}
}

impl Into<i64> for PlayerState {
	#[inline]
	fn into(self) -> i64 {
		match self {
			PlayerState::Idle(_) => 0,
			PlayerState::FWalk(_) => 1,
			PlayerState::BWalk(_) => 2,
			PlayerState::FDash(_) => 3,
			PlayerState::BDash(_) => 4,
			PlayerState::NNormal(_, _) => 8,
			PlayerState::MNormal(_, _) => 9,
			PlayerState::NSpecial(_, _) => 10,
			PlayerState::MSpecial(_, _) => 11,
			PlayerState::Dead(_) => 12,
		}
	}
}
