// Vitals data simulator
// Generates realistic-looking vital signs with random variation

function simulateHR() {
    return 65 + Math.floor(Math.random() * 35);
}

function simulateSpO2() {
    return 95 + Math.floor(Math.random() * 5);
}

function simulateRESP() {
    return 12 + Math.floor(Math.random() * 10);
}

function simulateNIBP() {
    return {
        sys: 110 + Math.floor(Math.random() * 30),
        dia: 65 + Math.floor(Math.random() * 20)
    };
}

function simulateTemp() {
    return (36.3 + Math.random() * 1.2).toFixed(1);
}

// ECG waveform generator (PQRST)
function ecgWave(phase) {
    if (phase < 0.1)
        return Math.sin(phase * 10 * Math.PI) * 0.15;
    else if (phase >= 0.15 && phase < 0.25) {
        if (phase < 0.17) return -0.25;
        else if (phase < 0.19) return 1.0;
        else if (phase < 0.21) return -0.35;
    }
    else if (phase >= 0.35 && phase < 0.5)
        return Math.sin((phase - 0.35) * 6 * Math.PI) * 0.2;
    return 0;
}

// Plethysmograph waveform (SpO2)
function plethWave(phase) {
    return Math.exp(-Math.pow((phase - 0.2) * 4, 2)) +
           0.3 * Math.exp(-Math.pow((phase - 0.5) * 6, 2));
}

// Respiration waveform
function respWave(phase) {
    return Math.sin(phase * 2 * Math.PI) * 0.7;
}