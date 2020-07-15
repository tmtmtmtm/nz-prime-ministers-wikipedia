module.exports = (id, startdate, enddate, replaces, replacedby) => {
  const qualifiers = { }

  // Seems like there should be a better way of filtering these...
  if (startdate && startdate != "''")   qualifiers['P580']  = startdate
  if (enddate && enddate != "''")       qualifiers['P582']  = enddate
  if (replaces && replaces != "''")     qualifiers['P1365'] = replaces
  if (replacedby && replacedby != "''") qualifiers['P1366'] = replacedby

  if (startdate && enddate && startdate != "''" && enddate != "''" &&
    (startdate > enddate)) throw new Error(`Invalid dates: ${startdate} / ${enddate}`)

  return {
    id,
    claims: {
      P39: {
        value: 'Q1071117', // position held: Prime Minister of New Zealand
        qualifiers: qualifiers,
        references: {
          P143: 'Q328', // enwiki
          P4656: 'https://en.wikipedia.org/wiki/List_of_prime_ministers_of_New_Zealand' // import URL
        },
      }
    }
  }
}
