const SENIORITY_TOKENS = new Set([
  'senior',
  'junior',
  'lead',
  'principal',
  'staff',
  'manager',
  'chef',
  'ansvarig'
]);

const MAX_QUERIES = 8;
const MIN_QUERY_LENGTH = 3;
const MAX_POOL = 200;
const MIN_POOL = 40;
const MAX_PER_OCCUPATION = 40;
const MAX_PIVOT_POOL = 180;
const MAX_PIVOT_PER_OCCUPATION = 24;
const MAX_PIVOT_QUERIES = 12;

module.exports = {
  SENIORITY_TOKENS,
  MAX_QUERIES,
  MIN_QUERY_LENGTH,
  MAX_POOL,
  MIN_POOL,
  MAX_PER_OCCUPATION,
  MAX_PIVOT_POOL,
  MAX_PIVOT_PER_OCCUPATION,
  MAX_PIVOT_QUERIES
};
