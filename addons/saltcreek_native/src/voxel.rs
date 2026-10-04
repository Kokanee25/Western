//! A small dense voxel volume for the foundation step: enough to voxelise a sphere, carve it and
//! mesh its visible faces. Step 2 replaces it with the brick volume from Pixel-factory's
//! src/volume.rs (bricks, mips, DDA) and real members.

pub struct Volume {
    pub dims: [usize; 3],
    pub voxel: f32,
    pub origin: [f32; 3],
    pub cells: Vec<u8>,
    pub solid: usize,
}

impl Volume {
    pub fn new(dims: [usize; 3], voxel: f32, origin: [f32; 3]) -> Volume {
        Volume { dims, voxel, origin, cells: vec![0; dims[0] * dims[1] * dims[2]], solid: 0 }
    }

    #[inline]
    fn idx(&self, x: usize, y: usize, z: usize) -> usize {
        (z * self.dims[1] + y) * self.dims[0] + x
    }

    #[inline]
    pub fn get(&self, x: i64, y: i64, z: i64) -> u8 {
        if x < 0 || y < 0 || z < 0 || x >= self.dims[0] as i64 || y >= self.dims[1] as i64 || z >= self.dims[2] as i64 {
            return 0;
        }
        self.cells[self.idx(x as usize, y as usize, z as usize)]
    }

    pub fn centre(&self, x: usize, y: usize, z: usize) -> [f32; 3] {
        [
            self.origin[0] + (x as f32 + 0.5) * self.voxel,
            self.origin[1] + (y as f32 + 0.5) * self.voxel,
            self.origin[2] + (z as f32 + 0.5) * self.voxel,
        ]
    }

    /// A solid sphere of `radius` metres centred at the origin.
    pub fn sphere(radius: f32, per_m: f32) -> Volume {
        let voxel = 1.0 / per_m;
        let n = ((radius * 2.0) / voxel).ceil() as usize + 2;
        let mut v = Volume::new([n, n, n], voxel, [-(n as f32) * voxel * 0.5; 3]);
        for z in 0..n {
            for y in 0..n {
                for x in 0..n {
                    let c = v.centre(x, y, z);
                    if c[0] * c[0] + c[1] * c[1] + c[2] * c[2] <= radius * radius {
                        let i = v.idx(x, y, z);
                        v.cells[i] = 1;
                        v.solid += 1;
                    }
                }
            }
        }
        v
    }

    /// Carve out everything within `r` of `at` (metres). Returns the voxels removed.
    pub fn carve_sphere(&mut self, at: [f32; 3], r: f32) -> usize {
        let mut removed = 0;
        for z in 0..self.dims[2] {
            for y in 0..self.dims[1] {
                for x in 0..self.dims[0] {
                    let i = self.idx(x, y, z);
                    if self.cells[i] == 0 {
                        continue;
                    }
                    let c = self.centre(x, y, z);
                    let d = [c[0] - at[0], c[1] - at[1], c[2] - at[2]];
                    if d[0] * d[0] + d[1] * d[1] + d[2] * d[2] <= r * r {
                        self.cells[i] = 0;
                        removed += 1;
                    }
                }
            }
        }
        self.solid -= removed;
        removed
    }

    /// Every visible cube face as two triangles (positions, normals, colours). Colour darkens
    /// toward the volume's centre so a carve shows as a darker bite.
    #[allow(clippy::type_complexity)]
    pub fn mesh_faces(&self) -> (Vec<[f32; 3]>, Vec<[f32; 3]>, Vec<[f32; 4]>) {
        let mut pos = Vec::new();
        let mut nrm = Vec::new();
        let mut col = Vec::new();
        let h = self.voxel * 0.5;
        const DIRS: [([i64; 3], [[f32; 3]; 4]); 6] = [
            ([1, 0, 0], [[1.0, -1.0, -1.0], [1.0, 1.0, -1.0], [1.0, 1.0, 1.0], [1.0, -1.0, 1.0]]),
            ([-1, 0, 0], [[-1.0, -1.0, 1.0], [-1.0, 1.0, 1.0], [-1.0, 1.0, -1.0], [-1.0, -1.0, -1.0]]),
            ([0, 1, 0], [[-1.0, 1.0, -1.0], [-1.0, 1.0, 1.0], [1.0, 1.0, 1.0], [1.0, 1.0, -1.0]]),
            ([0, -1, 0], [[-1.0, -1.0, 1.0], [-1.0, -1.0, -1.0], [1.0, -1.0, -1.0], [1.0, -1.0, 1.0]]),
            ([0, 0, 1], [[1.0, -1.0, 1.0], [1.0, 1.0, 1.0], [-1.0, 1.0, 1.0], [-1.0, -1.0, 1.0]]),
            ([0, 0, -1], [[-1.0, -1.0, -1.0], [-1.0, 1.0, -1.0], [1.0, 1.0, -1.0], [1.0, -1.0, -1.0]]),
        ];
        let extent = self.dims[0] as f32 * self.voxel * 0.5;
        for z in 0..self.dims[2] {
            for y in 0..self.dims[1] {
                for x in 0..self.dims[0] {
                    if self.cells[self.idx(x, y, z)] == 0 {
                        continue;
                    }
                    let c = self.centre(x, y, z);
                    let depth = 1.0 - ((c[0] * c[0] + c[1] * c[1] + c[2] * c[2]).sqrt() / extent).min(1.0);
                    let shade = [0.55 - 0.3 * depth, 0.36 - 0.2 * depth, 0.2 - 0.1 * depth, 1.0];
                    for (d, corners) in DIRS.iter() {
                        if self.get(x as i64 + d[0], y as i64 + d[1], z as i64 + d[2]) != 0 {
                            continue;
                        }
                        let n = [d[0] as f32, d[1] as f32, d[2] as f32];
                        let p: Vec<[f32; 3]> = corners.iter().map(|k| [c[0] + k[0] * h, c[1] + k[1] * h, c[2] + k[2] * h]).collect();
                        // Godot winds triangles clockwise when seen from the front.
                        for tri in [[0, 2, 1], [0, 3, 2]] {
                            for i in tri {
                                pos.push(p[i]);
                                nrm.push(n);
                                col.push(shade);
                            }
                        }
                    }
                }
            }
        }
        (pos, nrm, col)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn a_sphere_has_the_right_volume_and_a_bite_removes_some() {
        let mut v = Volume::sphere(0.5, 64.0);
        let got = v.solid as f32 / 64.0f32.powi(3);
        let want = 4.0 / 3.0 * std::f32::consts::PI * 0.125;
        assert!((got - want).abs() / want < 0.02, "{} vs {}", got, want);
        let before = v.solid;
        let removed = v.carve_sphere([0.5, 0.0, 0.0], 0.2);
        assert!(removed > 0 && v.solid == before - removed);
        let (p, n, c) = v.mesh_faces();
        assert!(p.len() % 3 == 0 && p.len() == n.len() && n.len() == c.len() && !p.is_empty());
    }
}
