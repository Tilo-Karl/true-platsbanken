const MAX_TRACK_RESULTS = 5;
const MAX_OCCUPATIONS_PER_TRACK = 12;
const MAX_EDUCATIONS_PER_OCCUPATION = 8;
const MIN_STRENGTHEN_RESULTS = 2;
const PIVOT_MIN_FAMILIES = 3;
const PIVOT_MAX_FAMILIES = 5;
const PIVOT_JOB_TITLES_PER_FAMILY = 2;
const PIVOT_MAX_ITEMS_PER_FAMILY = 2;
const PIVOT_MAX_ITEMS_PER_OCCUPATION = 1;

const PIVOT_CAPABILITY_FAMILIES = [
  {
    id: 'delivery_coordination',
    label: 'Delivery and coordination',
    evidencePrefixes: ['agil', 'scrum', 'roadmap', 'team', 'lead', 'stakeholder', 'projekt', 'plan'],
    targetPrefixes: ['projektled', 'samordn', 'processled', 'teamled', 'verksamhetsutveckl'],
    jobTitles: ['projektledare', 'processledare', 'samordnare']
  },
  {
    id: 'analysis_improvement',
    label: 'Analysis and improvement',
    evidencePrefixes: ['analys', 'data', 'kpi', 'rapport', 'roadmap', 'prioriter', 'strateg', 'förbättr'],
    targetPrefixes: ['analys', 'controller', 'utred', 'verksamhets', 'planer'],
    jobTitles: ['verksamhetsanalytiker', 'business analyst', 'controller']
  },
  {
    id: 'customer_commercial',
    label: 'Customer and commercial',
    evidencePrefixes: ['stakeholder', 'kund', 'kommun', 'relation', 'rådgiv', 'förhandl', 'sales', 'commercial'],
    targetPrefixes: ['kund', 'sälj', 'account', 'rådgiv', 'affär'],
    jobTitles: ['kundrådgivare', 'account manager', 'säljkoordinator']
  },
  {
    id: 'operations_planning',
    label: 'Operations and planning',
    evidencePrefixes: ['drift', 'leverans', 'plan', 'koord', 'resurs', 'flöd', 'support', 'incident'],
    targetPrefixes: ['logistik', 'produktion', 'inköp', 'planer', 'drift'],
    jobTitles: ['logistiker', 'produktionsplanerare', 'inköpare']
  },
  {
    id: 'quality_governance',
    label: 'Quality and governance',
    evidencePrefixes: ['kvalitet', 'process', 'risk', 'itil', 'säker', 'compliance', 'standard', 'revision'],
    targetPrefixes: ['kvalitet', 'miljö', 'säker', 'upphandling', 'revision'],
    jobTitles: ['kvalitetssamordnare', 'kvalitetstekniker', 'upphandlare']
  },
  {
    id: 'people_enablement',
    label: 'People enablement',
    evidencePrefixes: ['coach', 'handled', 'utbild', 'mento', 'facilit', 'onboard', 'ledning', 'team'],
    targetPrefixes: ['utbild', 'handled', 'coach', 'lärare', 'instrukt'],
    jobTitles: ['utbildningskoordinator', 'handledare', 'yrkeslärare']
  }
];

const PIVOT_BLOCKED_PREFIXES_WITHOUT_LEGAL_EVIDENCE = [
  'paralegal',
  'jurist',
  'jurid',
  'legal',
  'advokat',
  'administrat',
  'admin',
  'sekreter',
  'registrator',
  'handlägg',
  'case'
];

const LEGAL_EVIDENCE_PREFIXES = [
  'jurid',
  'legal',
  'compliance',
  'regelefterlev',
  'avtal',
  'upphandling',
  'case',
  'ärende',
  'handlägg'
];

const TECH_DOMAIN_PATTERNS = [
  'it',
  'tech',
  'tekn',
  'dev',
  'utveckl',
  'system',
  'mjukvar',
  'programmer',
  'backend',
  'frontend',
  'fullstack',
  'ios',
  'android',
  'cloud',
  'data',
  'databas',
  'ai',
  'api',
  'scrum',
  'agil'
];

module.exports = {
  MAX_TRACK_RESULTS,
  MAX_OCCUPATIONS_PER_TRACK,
  MAX_EDUCATIONS_PER_OCCUPATION,
  MIN_STRENGTHEN_RESULTS,
  PIVOT_MIN_FAMILIES,
  PIVOT_MAX_FAMILIES,
  PIVOT_JOB_TITLES_PER_FAMILY,
  PIVOT_MAX_ITEMS_PER_FAMILY,
  PIVOT_MAX_ITEMS_PER_OCCUPATION,
  PIVOT_CAPABILITY_FAMILIES,
  PIVOT_BLOCKED_PREFIXES_WITHOUT_LEGAL_EVIDENCE,
  LEGAL_EVIDENCE_PREFIXES,
  TECH_DOMAIN_PATTERNS
};
