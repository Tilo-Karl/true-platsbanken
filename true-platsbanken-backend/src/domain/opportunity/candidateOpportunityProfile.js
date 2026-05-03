const { getTaxonomySnapshot } = require('../taxonomy/jobTechTaxonomy');
const { resolveOccupationIds } = require('../matching/occupationResolver');

const DOMAIN_RULES = [
  {
    id: 'it_software_product',
    label: 'IT / software / product',
    prefixes: ['it', 'mjukvar', 'system', 'utveckl', 'programmer', 'backend', 'frontend', 'produkt', 'tech', 'cloud', 'ai']
  },
  {
    id: 'delivery_leadership',
    label: 'delivery / leadership',
    prefixes: ['team', 'lead', 'ledning', 'chef', 'projekt', 'leverans', 'agil', 'scrum', 'stakeholder', 'roadmap']
  },
  {
    id: 'logistics_operations',
    label: 'logistics / warehouse / operations',
    prefixes: ['logistik', 'lager', 'terminal', 'transport', 'drift', 'operat', 'planer', 'produktion', 'supply', 'inköp']
  },
  {
    id: 'customer_commercial',
    label: 'customer / commercial',
    prefixes: ['kund', 'rådgiv', 'sales', 'sälj', 'account', 'affär', 'service', 'kommun']
  },
  {
    id: 'quality_governance',
    label: 'quality / governance',
    prefixes: ['kvalitet', 'process', 'compliance', 'risk', 'säker', 'itil', 'standard', 'revision']
  },
  {
    id: 'people_enablement',
    label: 'people / training',
    prefixes: ['coach', 'utbild', 'handled', 'mento', 'facilit', 'onboard', 'instrukt']
  }
];

const CAPABILITY_RULES = [
  { label: 'leadership', prefixes: ['lead', 'ledning', 'chef', 'team', 'ansvar'] },
  { label: 'planning', prefixes: ['plan', 'roadmap', 'prioriter', 'schema', 'resurs'] },
  { label: 'coordination', prefixes: ['koord', 'samord', 'stakeholder', 'gränssnitt'] },
  { label: 'systems thinking', prefixes: ['system', 'process', 'helhet', 'arkitektur'] },
  { label: 'stakeholder communication', prefixes: ['stakeholder', 'kommun', 'presentation', 'förankr', 'kund'] },
  { label: 'operational discipline', prefixes: ['drift', 'incident', 'uppfölj', 'kvalitet', 'förbättr', 'leverans'] },
  { label: 'technical literacy', prefixes: ['it', 'tech', 'digital', 'data', 'api', 'mjukvar'] }
];

const WORK_ENVIRONMENT_RULES = [
  { label: 'cross-functional teams', prefixes: ['cross functional', 'tvärfunktion', 'stakeholder', 'team'] },
  { label: 'operations-heavy', prefixes: ['drift', 'logistik', 'produktion', 'lager', 'terminal'] },
  { label: 'customer-facing', prefixes: ['kund', 'rådgiv', 'service', 'account'] },
  { label: 'delivery-driven', prefixes: ['leverans', 'projekt', 'agil', 'roadmap'] }
];

const PIVOT_FAMILY_RULES = [
  {
    id: 'logistics_coordination',
    label: 'logistics coordination',
    domainId: 'logistics_operations',
    evidencePrefixes: ['plan', 'koord', 'leverans', 'process', 'resurs', 'drift'],
    capabilityHints: ['planning', 'coordination', 'operational discipline'],
    occupationSeeds: ['Logistikkoordinator', 'Transportledare', 'Lagerkoordinator'],
    searchTerms: ['logistik koordinator', 'transport koordinator', 'lager samordnare']
  },
  {
    id: 'transport_coordination',
    label: 'transport coordination',
    domainId: 'logistics_operations',
    evidencePrefixes: ['plan', 'samord', 'flöd', 'leverans', 'drift'],
    capabilityHints: ['planning', 'coordination', 'operational discipline'],
    occupationSeeds: ['Transportledare', 'Trafikledare', 'Speditör'],
    searchTerms: ['transportledare', 'trafikledning', 'spedition']
  },
  {
    id: 'operations_leadership',
    label: 'operations leadership',
    domainId: 'delivery_leadership',
    evidencePrefixes: ['team', 'ledning', 'drift', 'leverans', 'process', 'förbättr'],
    capabilityHints: ['leadership', 'operational discipline', 'systems thinking'],
    occupationSeeds: ['Driftledare', 'Produktionsledare', 'Arbetsledare'],
    searchTerms: ['driftledare', 'operations manager', 'arbetsledare']
  },
  {
    id: 'supply_chain_purchasing',
    label: 'supply chain / purchasing',
    domainId: 'logistics_operations',
    evidencePrefixes: ['plan', 'analys', 'kostnad', 'flöd', 'förhandl', 'inköp'],
    capabilityHints: ['planning', 'systems thinking', 'stakeholder communication'],
    occupationSeeds: ['Inköpare', 'Operativ inköpare', 'Supply chain planner'],
    searchTerms: ['inköpare', 'supply chain', 'operativt inköp']
  },
  {
    id: 'implementation_consulting',
    label: 'implementation consulting',
    domainId: 'customer_commercial',
    evidencePrefixes: ['stakeholder', 'kommun', 'förändr', 'process', 'implement', 'kund'],
    capabilityHints: ['coordination', 'stakeholder communication', 'technical literacy'],
    occupationSeeds: ['Verksamhetskonsult', 'Implementationskonsult', 'Kundansvarig'],
    searchTerms: ['implementationskonsult', 'verksamhetskonsult', 'onboarding specialist']
  },
  {
    id: 'technical_training',
    label: 'technical training',
    domainId: 'people_enablement',
    evidencePrefixes: ['coach', 'utbild', 'handled', 'facilit', 'presentation', 'team'],
    capabilityHints: ['leadership', 'stakeholder communication', 'technical literacy'],
    occupationSeeds: ['Teknisk utbildare', 'Handledare', 'Instruktör'],
    searchTerms: ['teknisk utbildare', 'instruktör', 'handledare']
  },
  {
    id: 'service_delivery_driftledning',
    label: 'service delivery / driftledning',
    domainId: 'delivery_leadership',
    evidencePrefixes: ['drift', 'incident', 'itil', 'leverans', 'service', 'uppfölj'],
    capabilityHints: ['operational discipline', 'coordination', 'systems thinking'],
    occupationSeeds: ['Service Delivery Manager', 'Driftledare', 'Förvaltningsledare'],
    searchTerms: ['service delivery manager', 'driftledning', 'förvaltningsledare']
  },
  {
    id: 'warehouse_terminal_leadership',
    label: 'warehouse / terminal leadership',
    domainId: 'logistics_operations',
    evidencePrefixes: ['ledning', 'plan', 'logistik', 'lager', 'terminal', 'flöd'],
    capabilityHints: ['leadership', 'planning', 'operational discipline'],
    occupationSeeds: ['Lagerchef', 'Terminalchef', 'Arbetsledare lager'],
    searchTerms: ['lagerchef', 'terminalledare', 'arbetsledare lager']
  }
];

async function buildCandidateOpportunityProfile(input = {}) {
  const explicitRoles = uniqueStrings(input.explicitRoles);
  const inferredRoles = uniqueStrings(input.inferredRoles);
  const summary = String(input.summary || '').trim();
  const profileSignals = uniqueStrings(input.profileSignals);
  const coreOccupationIds = uniqueStrings(input.coreOccupationIds);

  const tokenSet = buildTokenSet([
    ...explicitRoles,
    ...inferredRoles,
    ...profileSignals,
    summary
  ]);

  const domainScores = DOMAIN_RULES
    .map((rule) => ({
      ...rule,
      score: countPrefixHits(tokenSet, rule.prefixes)
    }))
    .filter((rule) => rule.score > 0)
    .sort((a, b) => b.score - a.score || a.label.localeCompare(b.label));

  const primaryDomains = domainScores.slice(0, 2).map((rule) => rule.label);
  const secondaryDomains = domainScores.slice(2, 4).map((rule) => rule.label);

  const transferableCapabilities = CAPABILITY_RULES
    .map((rule) => ({
      label: rule.label,
      score: countPrefixHits(tokenSet, rule.prefixes)
    }))
    .filter((rule) => rule.score > 0)
    .sort((a, b) => b.score - a.score || a.label.localeCompare(b.label))
    .map((rule) => rule.label);

  const workEnvironments = WORK_ENVIRONMENT_RULES
    .map((rule) => ({
      label: rule.label,
      score: countPrefixHits(tokenSet, rule.prefixes)
    }))
    .filter((rule) => rule.score > 0)
    .sort((a, b) => b.score - a.score || a.label.localeCompare(b.label))
    .map((rule) => rule.label);

  const familyProfiles = scorePivotFamilies({
    tokenSet,
    primaryDomainIds: new Set(domainScores.slice(0, 2).map((rule) => rule.id)),
    transferableCapabilities
  });

  const selectedPivotFamilies = familyProfiles
    .filter((family) => family.fitScore > 0)
    .slice(0, 5);

  const lowLeverageFamilies = familyProfiles
    .filter((family) => family.fitScore <= 0)
    .slice(0, 4)
    .map((family) => family.label);

  const pivotOpportunityFamilies = await enrichPivotFamiliesWithOccupationIds(selectedPivotFamilies);

  const coreOccupationTargets = await resolveOccupationTargets(coreOccupationIds);

  return {
    primaryDomains,
    secondaryDomains,
    transferableCapabilities,
    workEnvironments,
    careerStage: inferCareerStage(tokenSet),
    coreOccupationTargets,
    pivotOpportunityFamilies,
    lowLeverageFamilies
  };
}

function scorePivotFamilies({ tokenSet, primaryDomainIds, transferableCapabilities }) {
  const capabilitySet = new Set(transferableCapabilities.map((value) => value.toLowerCase()));

  return PIVOT_FAMILY_RULES
    .map((family) => {
      const evidence = countPrefixHits(tokenSet, family.evidencePrefixes);
      const capabilityBoost = family.capabilityHints.filter((hint) =>
        capabilitySet.has(hint.toLowerCase())
      ).length;
      const novelty = primaryDomainIds.has(family.domainId) ? -2 : 2;
      const transitionCost = primaryDomainIds.has(family.domainId) ? 1 : 0;
      const opportunityUpside = family.domainId === 'logistics_operations' ? 2 : 1;
      const fitScore = evidence * 2 + capabilityBoost * 2 + novelty + opportunityUpside - transitionCost;

      return {
        id: family.id,
        label: family.label,
        domainId: family.domainId,
        occupationSeeds: family.occupationSeeds,
        searchTerms: family.searchTerms,
        evidenceScore: evidence,
        capabilityScore: capabilityBoost,
        fitScore
      };
    })
    .sort((a, b) => b.fitScore - a.fitScore || a.label.localeCompare(b.label));
}

async function enrichPivotFamiliesWithOccupationIds(families) {
  if (!Array.isArray(families) || !families.length) return [];

  const uniqueSeeds = uniqueStrings(
    families.flatMap((family) => family.occupationSeeds || [])
  );
  const resolved = await resolveOccupationIds(uniqueSeeds, []);
  const resolvedByRole = resolved.resolved || {};

  return families.map((family) => {
    const occupationIds = uniqueStrings(
      (family.occupationSeeds || [])
        .map((seed) => resolvedByRole[seed]?.id)
        .filter(Boolean)
    );

    return {
      id: family.id,
      label: family.label,
      fitScore: family.fitScore,
      evidenceScore: family.evidenceScore,
      capabilityScore: family.capabilityScore,
      occupationIds,
      occupationSeeds: family.occupationSeeds,
      searchTerms: family.searchTerms
    };
  });
}

async function resolveOccupationTargets(occupationIds) {
  if (!Array.isArray(occupationIds) || !occupationIds.length) return [];
  const taxonomy = await getTaxonomySnapshot();
  return occupationIds.map((occupationId) => {
    const label = taxonomy.occupationById.get(occupationId)?.label || occupationId;
    return { occupationId, occupationLabel: label };
  });
}

function inferCareerStage(tokenSet) {
  if (hasAnyPrefix(tokenSet, ['junior', 'traine', 'entry'])) {
    return 'early';
  }

  if (hasAnyPrefix(tokenSet, ['senior', 'lead', 'manager', 'chef', 'principal', 'staff'])) {
    return 'advanced';
  }

  return 'mid';
}

function buildTokenSet(values) {
  const text = uniqueStrings(values).join(' ');
  return new Set(tokenizeStemmed(text));
}

function countPrefixHits(tokenSet, prefixes) {
  if (!(tokenSet instanceof Set) || !tokenSet.size || !Array.isArray(prefixes)) {
    return 0;
  }
  let score = 0;
  for (const token of tokenSet) {
    if (prefixes.some((prefix) => token.startsWith(prefix))) {
      score += 1;
    }
  }
  return score;
}

function hasAnyPrefix(tokenSet, prefixes) {
  return countPrefixHits(tokenSet, prefixes) > 0;
}

function tokenizeStemmed(value) {
  const normalized = String(value || '')
    .toLowerCase()
    .replace(/[^\p{L}\p{N}]+/gu, ' ')
    .trim();
  if (!normalized) return [];

  const rawTokens = normalized.split(/\s+/).filter(Boolean);
  const compacted = [];
  for (const token of rawTokens) {
    const stem = stemToken(token);
    if (!stem) continue;
    if (compacted[compacted.length - 1] === stem) continue;
    compacted.push(stem);
  }
  return compacted;
}

function stemToken(token) {
  return String(token || '')
    .replace(/(erna|ande|heten|elser|elserna|arna|orna)$/u, '')
    .replace(/(ing|ion|are|er|or|en|et|ad|at|a|e)$/u, '')
    .trim();
}

function uniqueStrings(values) {
  if (!Array.isArray(values)) return [];
  const seen = new Set();
  const result = [];
  for (const value of values) {
    const text = String(value || '').trim();
    if (!text) continue;
    const key = text.toLowerCase();
    if (seen.has(key)) continue;
    seen.add(key);
    result.push(text);
  }
  return result;
}

module.exports = { buildCandidateOpportunityProfile };
