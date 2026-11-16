#!/usr/bin/env bash
# F1 · Arkitektura (afati: e mërkurë, 18 nëntor 2026, 23:59; tag: f1)
# Përdorimi: bash check-f1.sh [--build] [--strict]   (nga rrënja e repos, ose REPO=/rruga bash check-f1.sh)
. "$(dirname "$0")/_lib.sh"
echo "${C_B}F1 · Arkitektura${C_Z}  (repo: $(pwd), tag: f1, afati: e mërkurë 18 nëntor 2026, 23:59)"

hdr "F1 · README dhe AGENTS.md"
ck "README.md ekziston dhe nuk është bosh" "krijoni README.md me idenë dhe mënyrën e nisjes" nonempty README.md
if [ -s README.md ]; then
  ck "README: ideja e projektit (të paktën 8 rreshta teksti)" "shpjegoni idenë: kush e përdor, çfarë problemi zgjidh" test "$(grep -cE '\S' README.md)" -ge 8
  ck "README: si niset projekti (komandat)" "shtoni seksionin 'Nisja' me komandat (p.sh. docker compose up --build)" grep -qiE 'docker[ -]compose|make |npm (run|start)|dotnet run|go run|uvicorn|mvn |gradle|python|nisja|how to run' README.md
  ck "README nuk është shablloni i starter-repos" "zëvendësoni përmbajtjen me idenë tuaj" test "$(grep -c '104CEC – starter repo' README.md)" -eq 0
fi
ck "AGENTS.md ekziston dhe nuk është bosh (rregullat për agjentët e kodimit)" "krijoni AGENTS.md: struktura, komandat, rregullat për AI-n" nonempty AGENTS.md

hdr "F1 · SLO (docs/slo.md)"
S=docs/slo.md
if [ ! -s "$S" ]; then bad "$S ekziston" "krijoni $S me të paktën 2 SLO me numra (p.sh. p95 < 300 ms; disponueshmëria 99.5%)"
else
  ok "$S ekziston"
  n=$(count_lines '[0-9]+([.,][0-9]+)? ?(ms|s|sek|%)' "$S")
  [ "${n:-0}" -ge 2 ] && ok "të paktën 2 rreshta me objektiv numerik ($n)" || bad "të paktën 2 SLO me objektiv numerik (njësi: ms, s, %); u gjetën ${n:-0}" "shkruani p.sh. 'p95 e /orders < 300 ms' dhe 'disponueshmëria ≥ 99.5%'"
  grep -iE '(p ?(50|75|90|95|99)|percentil|persentil)' "$S" | grep -qiE '[0-9] ?(ms|s|sek)' \
    && ok "SLO i vonesës me percentil + milisekonda" || bad "SLO i vonesës me percentil dhe kohë (p95 + ms)" "shtoni një rresht si 'vonesa p95 < 300 ms'"
  grep -qE '9[0-9]([.,][0-9]+)? ?%' "$S" \
    && ok "SLO i disponueshmërisë me përqindje" || bad "SLO i disponueshmërisë me përqindje (p.sh. 99.5%)" "shtoni një rresht si 'disponueshmëria ≥ 99.5%'"
  has_template_text "$S" && bad "$S ende përmban tekst shablloni" "hiqni rreshtat e shabllonit" || ok "$S pa tekst shablloni"
fi

hdr "F1 · Arkitektura (docs/architecture.md)"
A=docs/architecture.md
if [ ! -s "$A" ]; then bad "$A ekziston" "krijoni $A me C4 niveli 1 (konteksti) dhe niveli 2 (kontejnerët)"
else
  ok "$A ekziston"
  has_template_text "$A" && bad "$A nuk është më shablloni bosh" "hiqni rreshtat e shabllonit 'plotësohet nga ekipi'" || ok "$A pa tekst shablloni"
  ck "$A ka diagram (blloku mermaid/plantuml ose figurë)" "shtoni një bllok \`\`\`mermaid ose lidhje figure ![..](..)" has_diagram "$A"
  ck "$A përmend C4 niveli 1 (konteksti)" "shtoni seksionin 'C4 niveli 1: konteksti'" grep -qiE 'niveli 1|level 1|context|kontekst|L1' "$A"
  ck "$A përmend C4 niveli 2 (kontejnerët/shërbimet)" "shtoni seksionin 'C4 niveli 2: kontejnerët'" grep -qiE 'niveli 2|level 2|container|kontejner|L2' "$A"
fi

hdr "F1 · ADR (docs/adr/)"
na=$(list_files 'docs/adr/[0-9][0-9][0-9][0-9]-*.md' | grep -vc '/0000-')
[ "${na:-0}" -ge 3 ] && ok "$na ADR në docs/adr/" || bad "të paktën 3 ADR në docs/adr/NNNN-*.md (u gjetën ${na:-0})" "krijoni docs/adr/0002-<titulli>.md me kontekst, vendim, pasoja"
for f in $(list_files 'docs/adr/[0-9][0-9][0-9][0-9]-*.md' | grep -v '/0000-'); do
  grep -qiE 'konteksti|context' "$f" && grep -qiE 'vendimi|decision' "$f" && grep -qiE 'pasojat|consequences' "$f" \
    || soft "$f: mungon konteksti, vendimi ose pasojat" "shtoni titujt Konteksti / Vendimi / Pasojat"
done

hdr "F1 · Rreziqet (docs/risks.md)"
if [ ! -s docs/risks.md ]; then bad "docs/risks.md ekziston" "krijoni docs/risks.md: tabelë me të paktën 5 rreziqe (rreziku, gjasat, ndikimi, masa)"
else
  r=$(md_rows docs/risks.md); i=$(md_items docs/risks.md); [ "${i:-0}" -gt "${r:-0}" ] && r=$i
  [ "${r:-0}" -ge 5 ] && ok "docs/risks.md ka $r rreziqe" || bad "docs/risks.md duhet të ketë të paktën 5 rreshta (u gjetën ${r:-0})" "shtoni rreshta në tabelën e rreziqeve"
fi

hdr "F1 · Shërbimet (services/)"
s=$(count_services)
[ "$s" -ge 3 ] && ok "$s shërbime në services/: $(services | tr '\n' ' ')" || bad "të paktën 3 shërbime në services/<emri>/ (u gjetën $s)" "krijoni services/<emri>/ për secilin mikroshërbim"
for x in $(services); do
  svc_has_manifest "$x" && svc_has_source "$x" && ok "$x: skeleton (kod + fajll ndërtimi/varësish)" || bad "$x: skeleton me kod dhe Dockerfile/fajll varësish" "shtoni kodin fillestar dhe Dockerfile te services/$x/"
  grep_any '/health' "services/$x" && ok "$x: /health i përmendur në kod" || bad "$x: endpoint-i /health" "shtoni GET /health që kthen 200"
  [ -s "$A" ] && { grep -qi "$x" "$A" && ok "$x përmendet në $A" || bad "$x mungon në $A" "përshkruajeni $x në diagramin ose tabelën e shërbimeve"; }
done

hdr "F1 · Kontratat OpenAPI"
for x in $(services); do
  f=$(svc_openapi "$x")
  if [ -z "$f" ]; then bad "$x: kontrata OpenAPI" "vendoseni te contracts/$x.openapi.yaml (ose services/$x/openapi.*)"
  elif is_openapi "$f"; then ok "$x: $f është OpenAPI (ka openapi + paths)"
  else bad "$x: $f nuk duket OpenAPI (mungon 'openapi' ose 'paths')" "kontrata duhet të ketë openapi: 3.x dhe paths:"; fi
done
[ "$s" -eq 0 ] && bad "kontrata OpenAPI për çdo shërbim" "së pari krijoni shërbimet te services/"

hdr "F1 · Dorëzimi"
chk_journal f1
tag_check f1
build_checks
summary F1
