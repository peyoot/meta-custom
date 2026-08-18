// ECG waveform data generator (PQRST complex)
// Returns amplitude value for a given phase in [0, 1]

function ecgAmplitude(phase) {
    if (phase < 0.1)
        return Math.sin(phase * 10 * Math.PI) * 0.1;       // P wave
    else if (phase >= 0.15 && phase < 0.25) {
        if (phase < 0.17) return -0.2;                      // Q
        else if (phase < 0.19) return 1.0;                  // R peak
        else if (phase < 0.21) return -0.3;                 // S
    }
    else if (phase >= 0.35 && phase < 0.5)
        return Math.sin((phase - 0.35) * 6 * Math.PI) * 0.15; // T wave
    return 0;
}

function plethAmplitude(phase) {
    // SpO2 plethysmograph - dicrotic notch waveform
    var mainPeak = Math.exp(-Math.pow((phase - 0.2) * 5, 2));
    var dicrotic = 0.4 * Math.exp(-Math.pow((phase - 0.5) * 8, 2));
    return mainPeak + dicrotic;
}

function respAmplitude(phase) {
    // Respiration - sine wave
    return Math.sin(phase * 2 * Math.PI) * 0.8;
}