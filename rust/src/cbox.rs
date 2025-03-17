use std::ops;

#[derive(Clone, Copy, PartialEq, Eq, Debug)]
pub struct CBox {
	pub x: i16,
}

impl CBox {
	#[inline]
	pub const fn collision() -> Self {
		CBox { x: 125 }
	}

	#[inline]
	pub const fn base_hurtbox() -> Self {
		CBox { x: 158 }
	}

	pub fn overlap(self, offsetx1: i16, other: CBox, offsetx2: i16) -> bool {
		let c1x1 = offsetx1;
		let c1x2 = self.x + offsetx1;
		let c2x1 = offsetx2;
		let c2x2 = other.x + offsetx2;
		let c1xrange = (c1x1.min(c1x2), c1x1.max(c1x2));
		let c2xrange = (c2x1.min(c2x2), c2x1.max(c2x2));

		if c1xrange.0 >= c2xrange.1 || c2xrange.0 >= c1xrange.1 {
			return false;
		}

		true
	}

	#[inline]
	pub fn overlap_amount(&self, offsetx1: i16, other: CBox, offsetx2: i16) -> i16 {
		((self.x + offsetx1) - (other.x + offsetx2)) / 2
	}
}

impl ops::Mul<i16> for CBox {
	type Output = Self;

	fn mul(self, rhs: i16) -> Self::Output {
		CBox { x: self.x * rhs }
	}
}

impl ops::Neg for CBox {
	type Output = Self;

	fn neg(self) -> Self::Output {
		CBox { x: -self.x }
	}
}

macro_rules! cbox {
	($val:expr) => {
		if $val != 0 {
			Some(CBox { x: $val })
		} else {
			None
		}
	};
}

#[cfg(test)]
mod test {
	use super::*;

	#[test]
	fn dec_macro() {
		assert_eq!(cbox!(10), Some(CBox { x: 10 }));
		assert_eq!(cbox!(-10), Some(CBox { x: -10 }));
		assert_eq!(cbox!(0), None);
	}

	#[test]
	fn overlap() {
		let a = cbox!(10).unwrap();
		assert!(a.overlap(0, a, 0));
		assert!(a.overlap(0, -a, 19));
		assert!(!a.overlap(0, -a, 20));
	}

	#[test]
	fn overlap_amount() {
		let a = cbox!(10).unwrap();
		assert_eq!(a.overlap_amount(0, -a, 18), 1);
		assert_eq!(a.overlap_amount(0, -a, 20), 0);
	}
}
