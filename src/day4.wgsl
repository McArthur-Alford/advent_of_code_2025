@group(0) @binding(0)
var<storage, read_write> input: array<u32>;

@group(0) @binding(1)
var<storage, read_write> persist: array<u32>;

@compute @workgroup_size(16,16,1)
fn main(@builtin(global_invocation_id) gid: vec3<u32>) {
    if gid.x >= 135 || gid.y >= 135 {
        return;
    }

    let idx = gid.x + gid.y * 135;

        // Count up neighbours
    var sum: u32 = 0;
    for (var dy: i32 = -1; dy <= 1; dy = dy + 1) {
        for (var dx: i32 = -1; dx <= 1; dx = dx + 1) {
            let nx: i32 = i32(gid.x) + dx;
            let ny: i32 = i32(gid.y) + dy;


            let nidx: u32 = u32(nx) + u32(ny) * 135;
            let mask = (dx != 0 || dy != 0) && (nx >= 0 && nx < 135) && (ny >= 0 && ny < 135);

                // Yes this indexes out of bounds, no its not a problem
                // it prevents branching so its a win
            sum += input[nidx] * u32(mask);
        }
    }

    // If <4, this was accessible, mark it in persist
    let accessible = (sum < 4) && (input[idx] > 0);

    persist[idx] |= u32(accessible);

    workgroupBarrier();

    // Only keep inaccessible input as 1
    input[idx] &= u32(sum >= 4);
}
