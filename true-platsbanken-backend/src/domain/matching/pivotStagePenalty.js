const JUNIOR_TITLE_MARKERS = [
  'junior',
  'trainee',
  'entry level',
  'praktik',
  'intern'
];

const MANUAL_HEAVY_MARKERS = [
  'terminalarbet',
  'lagerarbet',
  'truckförare',
  'montör',
  'operatör',
  'chaufför',
  'plock',
  'pack',
  'städ',
  'butiksmedarbet',
  'bud'
];

const LEADERSHIP_MARKERS = [
  'manager',
  'chef',
  'lead',
  'ansvarig',
  'samordnare',
  'projektledare',
  'driftledare',
  'produktionsledare'
];

function stagePenalty({ job, stage, capabilities }) {
  const text = normalizeText([
    job?.title,
    job?.occupationLabel,
    job?.occupationGroupLabel,
    job?.description
  ].filter(Boolean).join(' '));

  const juniorHit = containsAny(text, JUNIOR_TITLE_MARKERS);
  const manualHit = containsAny(text, MANUAL_HEAVY_MARKERS);
  const leadershipHit = containsAny(text, LEADERSHIP_MARKERS);
  const leadershipCapability = Array.isArray(capabilities) && capabilities.includes('leadership');

  let penalty = 0;
  if (stage === 'advanced') {
    if (juniorHit) penalty += 0.2;
    if (manualHit) penalty += 0.24;
    if (leadershipHit) penalty -= 0.06;
  } else if (stage === 'mid') {
    if (juniorHit) penalty += 0.1;
    if (manualHit) penalty += 0.14;
    if (leadershipHit) penalty -= 0.03;
  } else {
    if (juniorHit) penalty += 0.04;
    if (manualHit) penalty += 0.06;
  }

  if (leadershipCapability && manualHit) {
    penalty += 0.05;
  }

  return Math.max(-0.08, Math.min(0.35, penalty));
}

function containsAny(text, needles) {
  if (!text || !Array.isArray(needles)) return false;
  return needles.some((needle) => text.includes(normalizeText(needle)));
}

function normalizeText(value) {
  return String(value || '')
    .toLowerCase()
    .replace(/[^\p{L}\p{N}]+/gu, ' ')
    .replace(/\s+/g, ' ')
    .trim();
}

module.exports = { stagePenalty };
