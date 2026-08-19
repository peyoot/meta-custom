.pragma library
// 波形数据发生器 —— 相位 phase 取值 [0, 1)

// ECG PQRST 复合波，幅值大致范围 [-0.3, 1.0]
function ecgAmplitude(phase) {
    if (phase < 0.10)
        return Math.sin(phase * 10 * Math.PI) * 0.12;          // P 波
    if (phase >= 0.15 && phase < 0.25) {                       // QRS 复合波
        if (phase < 0.17) return -0.18;                        // Q
        if (phase < 0.19) return 1.0;                          // R 尖峰
        if (phase < 0.21) return -0.32;                        // S
        return 0;
    }
    if (phase >= 0.35 && phase < 0.52)
        return Math.sin((phase - 0.35) * 5.9 * Math.PI) * 0.22; // T 波
    return 0;
}

// SpO2 容积波（带重搏切迹），范围约 [0, 1.4]
function plethAmplitude(phase) {
    var mainPeak = Math.exp(-Math.pow((phase - 0.22) * 5.0, 2));
    var dicrotic = 0.40 * Math.exp(-Math.pow((phase - 0.52) * 8.0, 2));
    return mainPeak + dicrotic;
}

// 呼吸波 —— 平滑正弦，范围 [-1, 1]
function respAmplitude(phase) {
    return Math.sin(phase * 2 * Math.PI) * 0.9;
}
