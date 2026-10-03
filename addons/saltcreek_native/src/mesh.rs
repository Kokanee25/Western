//! Meshing a member's volume: every visible cube face, merged into the biggest rectangles each
//! slice allows (greedy meshing), so a carved board is hundreds of triangles, not tens of
//! thousands. Two surfaces: faces on the member's own outside (textured exactly as
//! MemberMesh lays them: UVs in metres from the box's corner, grain along its length, UV2 the
//! whole face's size so the board's edge lines land where they did) and the carved faces inside
//! it, and the outside faces of wood torn round a hole (fresh wood; UV2 zero). Plus every triangle again as a soup for its collision shape.

use crate::volume::{torn, Volume};
use glam::{IVec3, Vec2, Vec3};

#[derive(Default, Clone)]
pub struct Surface {
    pub positions: Vec<Vec3>,
    pub normals: Vec<Vec3>,
    pub uv: Vec<Vec2>,
    pub uv2: Vec<Vec2>,
    pub indices: Vec<i32>,
}

impl Surface {
    pub fn triangles(&self) -> usize {
        self.indices.len() / 3
    }
}

#[derive(Default, Clone)]
pub struct MemberMesh {
    pub outer: Surface,
    pub inner: Surface,
    /// Every triangle, three points each (ConcavePolygonShape3D's faces).
    pub collision: Vec<Vec3>,
    pub millis: f32,
}

/// The grain runs along the member's longest side; on a face across it, u runs along the face's
/// longer side. As MemberMesh.box does it.
fn uv_axes(size: Vec3, face_axis: usize) -> (usize, usize) {
    let mut long = 0;
    for a in 0..3 {
        if size[a] > size[long] {
            long = a;
        }
    }
    let plane: Vec<usize> = (0..3).filter(|&a| a != face_axis).collect();
    let u = if long != face_axis {
        long
    } else if size[plane[0]] >= size[plane[1]] {
        plane[0]
    } else {
        plane[1]
    };
    let v = if plane[0] != u { plane[0] } else { plane[1] };
    (u, v)
}

pub fn mesh(vol: &Volume) -> MemberMesh {
    let t0 = std::time::Instant::now();
    let mut out = MemberMesh::default();
    let size = vol.size();
    for a in 0..3usize {
        let b = (a + 1) % 3;
        let c = (a + 2) % 3;
        let (nb, nc) = (vol.dims[b] as usize, vol.dims[c] as usize);
        let (u_axis, v_axis) = uv_axes(size, a);
        // 0 no face, 1 a face, 2 a torn voxel's face (fresh wood): rectangles merge like with like.
        let mut mask = vec![0u8; nb * nc];
        for sign in [1i32, -1] {
            for k in 0..vol.dims[a] {
                let mut any = false;
                for j in 0..nc {
                    for i in 0..nb {
                        let mut p = IVec3::ZERO;
                        p[a] = k;
                        p[b] = i as i32;
                        p[c] = j as i32;
                        let mut q = p;
                        q[a] += sign;
                        let v = vol.get(p);
                        let f = v != 0 && !vol.solid(q);
                        mask[j * nb + i] = if !f { 0 } else if torn(v) { 2 } else { 1 };
                        any |= f;
                    }
                }
                if !any {
                    continue;
                }
                let outer = (sign > 0 && k == vol.dims[a] - 1) || (sign < 0 && k == 0);
                let plane = vol.origin[a] + (k + if sign > 0 { 1 } else { 0 }) as f32 * vol.cell[a];
                // Greedy: the widest run along b, then as many rows along c as match it.
                for j in 0..nc {
                    let mut i = 0;
                    while i < nb {
                        let kind = mask[j * nb + i];
                        if kind == 0 {
                            i += 1;
                            continue;
                        }
                        let mut w = 1;
                        while i + w < nb && mask[j * nb + i + w] == kind {
                            w += 1;
                        }
                        let mut h = 1;
                        'rows: while j + h < nc {
                            for x in i..i + w {
                                if mask[(j + h) * nb + x] != kind {
                                    break 'rows;
                                }
                            }
                            h += 1;
                        }
                        for y in j..j + h {
                            for x in i..i + w {
                                mask[y * nb + x] = 0;
                            }
                        }
                        // A torn face is fresh wood, whether it's on the outside or carved.
                        let outer = outer && kind == 1;
                        let b0 = vol.origin[b] + i as f32 * vol.cell[b];
                        let b1 = vol.origin[b] + (i + w) as f32 * vol.cell[b];
                        let c0 = vol.origin[c] + j as f32 * vol.cell[c];
                        let c1 = vol.origin[c] + (j + h) as f32 * vol.cell[c];
                        let corner = |pb: f32, pc: f32| -> Vec3 {
                            let mut p = Vec3::ZERO;
                            p[a] = plane;
                            p[b] = pb;
                            p[c] = pc;
                            p
                        };
                        let quad = [corner(b0, c0), corner(b1, c0), corner(b1, c1), corner(b0, c1)];
                        let mut n = Vec3::ZERO;
                        n[a] = sign as f32;
                        let s = if outer { &mut out.outer } else { &mut out.inner };
                        let base = s.positions.len() as i32;
                        let face = if outer { Vec2::new(size[u_axis], size[v_axis]) } else { Vec2::ZERO };
                        for p in quad {
                            s.positions.push(p);
                            s.normals.push(n);
                            let from_corner = p - vol.origin;
                            s.uv.push(Vec2::new(from_corner[u_axis], from_corner[v_axis]));
                            s.uv2.push(face);
                        }
                        // b x c = a, so the corners go anticlockwise seen from +a; Godot's front
                        // faces are clockwise.
                        let tris: [i32; 6] = if sign > 0 { [0, 2, 1, 0, 3, 2] } else { [0, 1, 2, 0, 2, 3] };
                        for t in tris {
                            s.indices.push(base + t);
                        }
                        for t in tris {
                            out.collision.push(quad[t as usize]);
                        }
                        i += w;
                    }
                }
            }
        }
    }
    out.millis = t0.elapsed().as_secs_f32() * 1000.0;
    out
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::carve::Carve;
    use crate::volume::{material, pack};

    fn board() -> Volume {
        Volume::solid_box(Vec3::new(0.022, 0.15, 1.0), 96.0, 1 << 20, pack(0, 0, 0, material::WOOD))
    }

    #[test]
    fn an_uncarved_member_is_its_box() {
        let m = mesh(&board());
        assert_eq!(m.outer.triangles(), 12);
        assert_eq!(m.inner.triangles(), 0);
        assert_eq!(m.collision.len(), 36);
        // UVs from 0 to the face's size, as MemberMesh: the big face (normal x) runs u along the
        // board's length (z) and v across it (y).
        let i = m.outer.normals.iter().position(|n| n.x > 0.5).unwrap();
        assert_eq!(m.outer.uv2[i], Vec2::new(1.0, 0.15));
    }

    #[test]
    fn faces_wind_clockwise_seen_from_outside() {
        let mut v = board();
        v.carve(&Carve {
            entry: Vec3::new(-0.011, 0.0, 0.0),
            exit: Vec3::new(0.011, 0.0, 0.0),
            radius: 0.01,
            spall_m3: 5e-6,
            ragged: 0.5,
            flare: 0.5,
            grain: Some(2),
            grain_split: 2.0,
            seed: 3,
            island_max: 16,
            max_chunks: 4,
        });
        let m = mesh(&v);
        assert!(m.inner.triangles() > 0);
        for s in [&m.outer, &m.inner] {
            for t in s.indices.chunks(3) {
                let (p0, p1, p2) = (s.positions[t[0] as usize], s.positions[t[1] as usize], s.positions[t[2] as usize]);
                // Clockwise from the front: (p1-p0) x (p2-p0) points into the solid.
                let n = (p1 - p0).cross(p2 - p0);
                assert!(n.dot(s.normals[t[0] as usize]) < 0.0);
            }
        }
    }

    #[test]
    fn the_wood_round_a_hole_shows_fresh() {
        let mut v = board();
        v.carve(&Carve {
            entry: Vec3::new(-0.011, 0.0, 0.0),
            exit: Vec3::new(0.011, 0.0, 0.0),
            radius: 0.006,
            spall_m3: 0.0,
            ragged: 0.5,
            flare: 0.5,
            grain: Some(2),
            grain_split: 2.0,
            seed: 5,
            island_max: 16,
            max_chunks: 4,
        });
        let m = mesh(&v);
        // Faces on the board's front plane drawn as fresh wood: the torn ring round the hole.
        let front = v.max().x;
        let ring = m.inner.positions.iter().zip(m.inner.normals.iter()).filter(|(p, n)| n.x > 0.5 && (p.x - front).abs() < 1e-5).count();
        assert!(ring >= 4, "{}", ring);
    }

    #[test]
    fn the_mesh_is_closed() {
        // Every edge of a closed surface is used once each way: sum of the faces' signed areas
        // along each axis is zero.
        let mut v = board();
        v.carve(&Carve {
            entry: Vec3::new(-0.011, 0.02, 0.1),
            exit: Vec3::new(0.011, -0.01, 0.12),
            radius: 0.006,
            spall_m3: 12e-6,
            ragged: 0.6,
            flare: 0.5,
            grain: Some(2),
            grain_split: 2.0,
            seed: 9,
            island_max: 16,
            max_chunks: 4,
        });
        let m = mesh(&v);
        let mut area = Vec3::ZERO;
        for t in m.collision.chunks(3) {
            area += (t[1] - t[0]).cross(t[2] - t[0]);
        }
        assert!(area.abs().max_element() < 1e-6, "{:?}", area);
    }
}
