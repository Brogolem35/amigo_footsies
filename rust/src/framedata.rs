use crate::cbox::CBox;

#[derive(Clone)]
pub struct FrameData {
	pub speed: i16,
	pub collision: CBox,
	// Both hitbox and hurtbox used to be stored in a Box<[CBox]>,
	// but to squeeze out every bit of CPU and memory dur,ng training, I changed it to this mess.
	// If arrayvec or tinyvec crates had const ways to do this, I would used them.
	pub hitbox: Option<CBox>,
	pub hurtbox: [Option<CBox>; 2],
	pub cancel: bool,
}

impl FrameData {
	const fn default() -> Self {
		Self {
			speed: 0,
			collision: CBox::collision(),
			hitbox: None,
			hurtbox: [Some(CBox::base_hurtbox()), None],
			cancel: false,
		}
	}
}

#[derive(Clone)]
pub struct MoveData {
	pub data: FrameData,
	pub animation_frame: &'static str,
	pub duration: u8,
}

pub const IDLE_DATA: [MoveData; 5] = [
	MoveData {
		data: FrameData::default(),
		animation_frame: "idle_0",
		duration: 6,
	},
	MoveData {
		data: FrameData::default(),
		animation_frame: "idle_1",
		duration: 3,
	},
	MoveData {
		data: FrameData::default(),
		animation_frame: "idle_2",
		duration: 6,
	},
	MoveData {
		data: FrameData::default(),
		animation_frame: "idle_3",
		duration: 6,
	},
	MoveData {
		data: FrameData::default(),
		animation_frame: "idle_4",
		duration: 3,
	},
];

pub fn idle_data(frame: u8) -> Option<&'static MoveData> {
	let mut frame = (frame + 1) as usize;

	for d in IDLE_DATA.iter() {
		frame = frame.saturating_sub(d.duration as usize);

		if frame == 0 {
			return Some(d);
		}
	}

	None
}

pub const FWALK_DATA: [MoveData; 6] = [
	MoveData {
		data: FrameData {
			speed: 6,
			..FrameData::default()
		},
		animation_frame: "fwalk_0",
		duration: 4,
	},
	MoveData {
		data: FrameData {
			speed: 6,
			..FrameData::default()
		},
		animation_frame: "fwalk_1",
		duration: 4,
	},
	MoveData {
		data: FrameData {
			speed: 6,
			..FrameData::default()
		},
		animation_frame: "fwalk_2",
		duration: 4,
	},
	MoveData {
		data: FrameData {
			speed: 6,
			..FrameData::default()
		},
		animation_frame: "fwalk_3",
		duration: 4,
	},
	MoveData {
		data: FrameData {
			speed: 6,
			..FrameData::default()
		},
		animation_frame: "fwalk_4",
		duration: 4,
	},
	MoveData {
		data: FrameData {
			speed: 6,
			..FrameData::default()
		},
		animation_frame: "fwalk_5",
		duration: 4,
	},
];

pub fn fwalk_data(frame: u8) -> Option<&'static MoveData> {
	let mut frame = (frame + 1) as usize;

	for d in FWALK_DATA.iter() {
		frame = frame.saturating_sub(d.duration as usize);

		if frame == 0 {
			return Some(d);
		}
	}

	None
}

pub const BWALK_DATA: [MoveData; 6] = [
	MoveData {
		data: FrameData {
			speed: -5,
			..FrameData::default()
		},
		animation_frame: "bwalk_0",
		duration: 4,
	},
	MoveData {
		data: FrameData {
			speed: -5,
			..FrameData::default()
		},
		animation_frame: "bwalk_1",
		duration: 4,
	},
	MoveData {
		data: FrameData {
			speed: -5,
			..FrameData::default()
		},
		animation_frame: "bwalk_2",
		duration: 4,
	},
	MoveData {
		data: FrameData {
			speed: -5,
			..FrameData::default()
		},
		animation_frame: "bwalk_3",
		duration: 4,
	},
	MoveData {
		data: FrameData {
			speed: -5,
			..FrameData::default()
		},
		animation_frame: "bwalk_4",
		duration: 4,
	},
	MoveData {
		data: FrameData {
			speed: -5,
			..FrameData::default()
		},
		animation_frame: "bwalk_5",
		duration: 4,
	},
];

pub fn bwalk_data(frame: u8) -> Option<&'static MoveData> {
	let mut frame = (frame + 1) as usize;

	for d in BWALK_DATA.iter() {
		frame = frame.saturating_sub(d.duration as usize);

		if frame == 0 {
			return Some(d);
		}
	}

	None
}

pub const NNORMAL_DATA: [MoveData; 6] = [
	MoveData {
		data: FrameData {
			..FrameData::default()
		},
		animation_frame: "nnormal_0",
		duration: 2,
	},
	MoveData {
		data: FrameData {
			..FrameData::default()
		},
		animation_frame: "nnormal_1",
		duration: 3,
	},
	MoveData {
		data: FrameData {
			cancel: true,
			hitbox: Some(CBox { x: 299 }),
			hurtbox: [Some(CBox::base_hurtbox()), Some(CBox { x: 324 })],
			..FrameData::default()
		},
		animation_frame: "nnormal_2",
		duration: 2,
	},
	MoveData {
		data: FrameData {
			cancel: true,
			hurtbox: [Some(CBox::base_hurtbox()), Some(CBox { x: 324 })],
			..FrameData::default()
		},
		animation_frame: "nnormal_2",
		duration: 10,
	},
	MoveData {
		data: FrameData {
			hurtbox: [Some(CBox::base_hurtbox()), Some(CBox { x: 237 })],
			..FrameData::default()
		},
		animation_frame: "nnormal_3",
		duration: 4,
	},
	MoveData {
		data: FrameData {
			..FrameData::default()
		},
		animation_frame: "nnormal_4",
		duration: 2,
	},
];

pub fn nnormal_data(frame: u8) -> Option<&'static MoveData> {
	let mut frame = (frame + 1) as usize;

	for d in NNORMAL_DATA.iter() {
		frame = frame.saturating_sub(d.duration as usize);

		if frame == 0 {
			return Some(d);
		}
	}

	None
}

pub const MNORMAL_DATA: [MoveData; 6] = [
	MoveData {
		data: FrameData {
			..FrameData::default()
		},
		animation_frame: "mnormal_0",
		duration: 2,
	},
	MoveData {
		data: FrameData {
			..FrameData::default()
		},
		animation_frame: "mnormal_1",
		duration: 2,
	},
	MoveData {
		data: FrameData {
			cancel: true,
			hitbox: Some(CBox { x: 130 + 130 }),
			hurtbox: [Some(CBox::base_hurtbox()), Some(CBox { x: 260 })],
			..FrameData::default()
		},
		animation_frame: "mnormal_2",
		duration: 2,
	},
	MoveData {
		data: FrameData {
			cancel: true,
			hurtbox: [Some(CBox::base_hurtbox()), Some(CBox { x: 260 })],
			..FrameData::default()
		},
		animation_frame: "mnormal_2",
		duration: 10,
	},
	MoveData {
		data: FrameData {
			hurtbox: [Some(CBox::base_hurtbox()), Some(CBox { x: 222 })],
			..FrameData::default()
		},
		animation_frame: "mnormal_3",
		duration: 4,
	},
	MoveData {
		data: FrameData {
			..FrameData::default()
		},
		animation_frame: "mnormal_4",
		duration: 2,
	},
];

pub fn mnormal_data(frame: u8) -> Option<&'static MoveData> {
	let mut frame = (frame + 1) as usize;

	for d in MNORMAL_DATA.iter() {
		frame = frame.saturating_sub(d.duration as usize);

		if frame == 0 {
			return Some(d);
		}
	}

	None
}

pub const NSPECIAL_DATA: [MoveData; 12] = [
	MoveData {
		data: FrameData {
			speed: 10,
			..FrameData::default()
		},
		animation_frame: "nspecial_0",
		duration: 3,
	},
	MoveData {
		data: FrameData {
			speed: 13,
			..FrameData::default()
		},
		animation_frame: "nspecial_1",
		duration: 2,
	},
	MoveData {
		data: FrameData {
			speed: 16,
			..FrameData::default()
		},
		animation_frame: "nspecial_2",
		duration: 3,
	},
	MoveData {
		data: FrameData {
			speed: 16,
			..FrameData::default()
		},
		animation_frame: "nspecial_3",
		duration: 2,
	},
	MoveData {
		data: FrameData {
			speed: 16,
			..FrameData::default()
		},
		animation_frame: "nspecial_4",
		duration: 1,
	},
	MoveData {
		data: FrameData {
			speed: 16,
			hitbox: Some(CBox { x: 158 + 158 }),
			hurtbox: [Some(CBox::base_hurtbox()), Some(CBox { x: 254 })],
			..FrameData::default()
		},
		animation_frame: "nspecial_5",
		duration: 4,
	},
	MoveData {
		data: FrameData {
			speed: 6,
			hurtbox: [Some(CBox::base_hurtbox()), Some(CBox { x: 254 })],
			..FrameData::default()
		},
		animation_frame: "nspecial_5",
		duration: 2,
	},
	MoveData {
		data: FrameData {
			speed: 3,
			hurtbox: [Some(CBox::base_hurtbox()), Some(CBox { x: 254 })],
			..FrameData::default()
		},
		animation_frame: "nspecial_5",
		duration: 2,
	},
	MoveData {
		data: FrameData {
			hurtbox: [Some(CBox::base_hurtbox()), Some(CBox { x: 254 })],
			..FrameData::default()
		},
		animation_frame: "nspecial_5",
		duration: 7,
	},
	MoveData {
		data: FrameData {
			hurtbox: [Some(CBox::base_hurtbox()), Some(CBox { x: 240 })],
			..FrameData::default()
		},
		animation_frame: "nspecial_6",
		duration: 3,
	},
	MoveData {
		data: FrameData {
			..FrameData::default()
		},
		animation_frame: "nspecial_6",
		duration: 12,
	},
	MoveData {
		data: FrameData {
			..FrameData::default()
		},
		animation_frame: "nspecial_7",
		duration: 2,
	},
];

pub fn nspecial_data(frame: u8) -> Option<&'static MoveData> {
	let mut frame = (frame + 1) as usize;

	for d in NSPECIAL_DATA.iter() {
		frame = frame.saturating_sub(d.duration as usize);

		if frame == 0 {
			return Some(d);
		}
	}

	None
}

pub const MSPECIAL_DATA: [MoveData; 11] = [
	MoveData {
		data: FrameData {
			speed: 8,
			hurtbox: [None, None],
			..FrameData::default()
		},
		animation_frame: "mspecial_0",
		duration: 1,
	},
	MoveData {
		data: FrameData {
			speed: 8,
			hurtbox: [None, None],
			..FrameData::default()
		},
		animation_frame: "mspecial_1",
		duration: 1,
	},
	MoveData {
		data: FrameData {
			speed: 7,
			hitbox: Some(CBox { x: 190 }),
			hurtbox: [None, None],
			..FrameData::default()
		},
		animation_frame: "mspecial_2",
		duration: 1,
	},
	MoveData {
		data: FrameData {
			speed: 5,
			hitbox: Some(CBox { x: 190 }),
			hurtbox: [None, None],
			..FrameData::default()
		},
		animation_frame: "mspecial_2",
		duration: 3,
	},
	MoveData {
		data: FrameData {
			speed: 5,
			hitbox: Some(CBox { x: 190 }),
			..FrameData::default()
		},
		animation_frame: "mspecial_3",
		duration: 2,
	},
	MoveData {
		data: FrameData {
			speed: 5,
			..FrameData::default()
		},
		animation_frame: "mspecial_3",
		duration: 3,
	},
	MoveData {
		data: FrameData {
			speed: 3,
			..FrameData::default()
		},
		animation_frame: "mspecial_3",
		duration: 5,
	},
	MoveData {
		data: FrameData {
			..FrameData::default()
		},
		animation_frame: "mspecial_3",
		duration: 20,
	},
	MoveData {
		data: FrameData {
			..FrameData::default()
		},
		animation_frame: "mspecial_4",
		duration: 10,
	},
	MoveData {
		data: FrameData {
			..FrameData::default()
		},
		animation_frame: "mspecial_5",
		duration: 7,
	},
	MoveData {
		data: FrameData {
			..FrameData::default()
		},
		animation_frame: "mspecial_6",
		duration: 2,
	},
];

pub fn mspecial_data(frame: u8) -> Option<&'static MoveData> {
	let mut frame = (frame + 1) as usize;

	for d in MSPECIAL_DATA.iter() {
		frame = frame.saturating_sub(d.duration as usize);

		if frame == 0 {
			return Some(d);
		}
	}

	None
}

pub const FDASH_DATA: [MoveData; 9] = [
	MoveData {
		data: FrameData {
			speed: 13,
			..FrameData::default()
		},
		animation_frame: "fdash_0",
		duration: 3,
	},
	MoveData {
		data: FrameData {
			speed: 18,
			..FrameData::default()
		},
		animation_frame: "fdash_0",
		duration: 5,
	},
	MoveData {
		data: FrameData {
			speed: 18,
			..FrameData::default()
		},
		animation_frame: "fdash_1",
		duration: 1,
	},
	MoveData {
		data: FrameData {
			speed: 12,
			..FrameData::default()
		},
		animation_frame: "fdash_1",
		duration: 2,
	},
	MoveData {
		data: FrameData {
			speed: 12,
			..FrameData::default()
		},
		animation_frame: "fdash_2",
		duration: 1,
	},
	MoveData {
		data: FrameData {
			speed: 5,
			..FrameData::default()
		},
		animation_frame: "fdash_2",
		duration: 1,
	},
	MoveData {
		data: FrameData {
			speed: 5,
			..FrameData::default()
		},
		animation_frame: "fdash_3",
		duration: 1,
	},
	MoveData {
		data: FrameData {
			speed: 3,
			..FrameData::default()
		},
		animation_frame: "fdash_3",
		duration: 1,
	},
	MoveData {
		data: FrameData {
			..FrameData::default()
		},
		animation_frame: "fdash_4",
		duration: 1,
	},
];

pub fn fdash_data(frame: u8) -> Option<&'static MoveData> {
	let mut frame = (frame + 1) as usize;

	for d in FDASH_DATA.iter() {
		frame = frame.saturating_sub(d.duration as usize);

		if frame == 0 {
			return Some(d);
		}
	}

	None
}

pub const BDASH_DATA: [MoveData; 8] = [
	MoveData {
		data: FrameData {
			speed: -26,
			..FrameData::default()
		},
		animation_frame: "bdash_0",
		duration: 3,
	},
	MoveData {
		data: FrameData {
			speed: -12,
			..FrameData::default()
		},
		animation_frame: "bdash_0",
		duration: 6,
	},
	MoveData {
		data: FrameData {
			speed: -8,
			..FrameData::default()
		},
		animation_frame: "bdash_0",
		duration: 2,
	},
	MoveData {
		data: FrameData {
			speed: -8,
			..FrameData::default()
		},
		animation_frame: "bdash_1",
		duration: 2,
	},
	MoveData {
		data: FrameData {
			speed: -3,
			..FrameData::default()
		},
		animation_frame: "bdash_1",
		duration: 2,
	},
	MoveData {
		data: FrameData {
			..FrameData::default()
		},
		animation_frame: "bdash_1",
		duration: 2,
	},
	MoveData {
		data: FrameData {
			..FrameData::default()
		},
		animation_frame: "bdash_2",
		duration: 4,
	},
	MoveData {
		data: FrameData {
			..FrameData::default()
		},
		animation_frame: "bdash_3",
		duration: 1,
	},
];

pub fn bdash_data(frame: u8) -> Option<&'static MoveData> {
	let mut frame = (frame + 1) as usize;

	for d in BDASH_DATA.iter() {
		frame = frame.saturating_sub(d.duration as usize);

		if frame == 0 {
			return Some(d);
		}
	}

	None
}

pub fn dead_data() -> &'static MoveData {
	const DATA: MoveData = MoveData {
		data: FrameData {
			..FrameData::default()
		},
		animation_frame: "dead_0",
		duration: 1,
	};

	&DATA
}

#[allow(unused)]
pub const fn move_length(data: &[MoveData]) -> u8 {
	let mut i = 0;
	let mut res = 0;

	// Not used `for` to be const compatible
	while i < data.len() {
		res += data[i].duration;
		i += 1;
	}

	res
}
