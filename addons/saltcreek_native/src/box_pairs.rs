//! The support graph's broadphase (#1239): which members' boxes come within a reach of each other.
//! Structure.near_lists asks; its script sweep is the same rule (and the fallback on the web).
//! A sweep and prune along the axis the boxes overlap least on: sorted by their start there, each
//! box paired with those after it that start before it ends, then tested on the other two axes.

use godot::prelude::*;

/// For each box, the indices of the others within `slack` of it on every axis, ascending.
pub fn near(lo: &[[f64; 3]], hi: &[[f64; 3]], slack: f64) -> Vec<Vec<i32>> {
    let n = lo.len();
    let mut lists: Vec<Vec<i32>> = vec![Vec::new(); n];
    if n == 0 {
        return lists;
    }
    let mut sum = [0.0f64; 3];
    let mut mn = lo[0];
    let mut mx = hi[0];
    for i in 0..n {
        for a in 0..3 {
            sum[a] += hi[i][a] - lo[i][a];
            mn[a] = mn[a].min(lo[i][a]);
            mx[a] = mx[a].max(hi[i][a]);
        }
    }
    let d: Vec<f64> = (0..3).map(|a| sum[a] / (mx[a] - mn[a]).max(0.001)).collect();
    let axis = if d[0] <= d[1] && d[0] <= d[2] { 0 } else if d[1] <= d[2] { 1 } else { 2 };
    let (b, c) = ((axis + 1) % 3, (axis + 2) % 3);
    let mut order: Vec<usize> = (0..n).collect();
    order.sort_by(|&p, &q| lo[p][axis].total_cmp(&lo[q][axis]).then(p.cmp(&q)));
    for k in 0..n {
        let i = order[k];
        let stop = hi[i][axis] + slack;
        let (bl, bh) = (lo[i][b] - slack, hi[i][b] + slack);
        let (cl, ch) = (lo[i][c] - slack, hi[i][c] + slack);
        for &j in &order[k + 1..] {
            if lo[j][axis] > stop {
                break;
            }
            if lo[j][b] <= bh && hi[j][b] >= bl && lo[j][c] <= ch && hi[j][c] >= cl {
                lists[i].push(j as i32);
                lists[j].push(i as i32);
            }
        }
    }
    for l in lists.iter_mut() {
        l.sort_unstable();
    }
    lists
}

/// Made by ClassDB (the web export runs without the plugin).
#[derive(GodotClass)]
#[class(base = RefCounted, init)]
pub struct BoxPairs {
    base: Base<RefCounted>,
}

#[godot_api]
impl BoxPairs {
    /// Boxes as their corners (`lo[i]`, `hi[i]`). Returns CSR: n + 1 offsets into the neighbours
    /// that follow them, so box i's are out[n + 1 + out[i] .. n + 1 + out[i + 1]].
    #[func]
    fn near(&self, lo: PackedVector3Array, hi: PackedVector3Array, slack: f64) -> PackedInt32Array {
        let v = |p: &Vector3| [p.x as f64, p.y as f64, p.z as f64];
        let lo: Vec<[f64; 3]> = lo.as_slice().iter().map(v).collect();
        let hi: Vec<[f64; 3]> = hi.as_slice().iter().map(v).collect();
        let n = lo.len().min(hi.len());
        let lists = near(&lo[..n], &hi[..n], slack);
        let total: usize = lists.iter().map(|l| l.len()).sum();
        let mut out: Vec<i32> = Vec::with_capacity(n + 1 + total);
        let mut at = 0i32;
        out.push(0);
        for l in &lists {
            at += l.len() as i32;
            out.push(at);
        }
        for l in &lists {
            out.extend_from_slice(l);
        }
        PackedInt32Array::from(out.as_slice())
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn pairs_within_reach_ascending() {
        let lo = [[0.0, 0.0, 0.0], [1.005, 0.0, 0.0], [5.0, 5.0, 5.0], [0.5, 0.5, 0.5]];
        let hi = [[1.0, 1.0, 1.0], [2.0, 1.0, 1.0], [6.0, 6.0, 6.0], [0.6, 0.6, 0.6]];
        let l = near(&lo, &hi, 0.01);
        assert_eq!(l[0], vec![1, 3]);
        assert_eq!(l[1], vec![0]);
        assert!(l[2].is_empty());
        assert_eq!(l[3], vec![0]);
    }
}
