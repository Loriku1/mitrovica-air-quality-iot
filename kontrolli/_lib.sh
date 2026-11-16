#!/usr/bin/env bash
# _lib.sh · funksione të përbashkëta për check-f1.sh … check-f7.sh (burimohet, nuk ekzekutohet vetë).
# Vetëm bash, grep, sed, awk, git. docker / kubectl përdoren vetëm me --build / --cluster.
# Kontrollon vetëm ekzistencën, strukturën, tag-un dhe grep-e. Nuk jep pikë dhe nuk gjykon cilësinë.

KDIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
OK=0; FAIL=0; WARN=0
BUILD=0; CLUSTER=0; STRICT=0

usage() {
  cat <<'EOF'
Përdorimi:  bash check-fN.sh [--build] [--cluster] [--strict]
  (nga rrënja e repos tuaj, ose:  REPO=/rruga/e/repos bash check-fN.sh)
  --build    edhe docker compose up --build --wait + /health, pastaj down (kërkon Docker)
  --cluster  edhe aplikim i manifesteve në një cluster lokal ekzistues (kind/k3s) + pritje rollout (kërkon kubectl)
  --strict   disa paralajmërime (!) bëhen ✗ (p.sh. tag-u mungon, kontrolle opsionale)
Kodi i daljes = numri i ✗ (maksimumi 99). ✓ = në rregull, ✗ = duhet rregulluar, ! = kujdes/anashkaluar.
EOF
}
for a in "$@"; do
  case "$a" in
    --build) BUILD=1 ;;
    --cluster) CLUSTER=1 ;;
    --strict) STRICT=1 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Flamur i panjohur: $a"; usage; exit 99 ;;
  esac
done

if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
  C_G=$'\033[32m'; C_R=$'\033[31m'; C_Y=$'\033[33m'; C_B=$'\033[1m'; C_Z=$'\033[0m'
else
  C_G=''; C_R=''; C_Y=''; C_B=''; C_Z=''
fi

ok()   { printf '  %s✓%s %s\n' "$C_G" "$C_Z" "$1"; OK=$((OK + 1)); }
bad()  { printf '  %s✗%s %s\n' "$C_R" "$C_Z" "$1"; [ -n "${2:-}" ] && printf '      ↳ Si ta rregulloni: %s\n' "$2"; FAIL=$((FAIL + 1)); }
warn() { printf '  %s!%s %s\n' "$C_Y" "$C_Z" "$1"; WARN=$((WARN + 1)); }
soft() { if [ "$STRICT" = 1 ]; then bad "$1" "${2:-}"; else warn "$1"; fi; }   # ! normalisht, ✗ me --strict
hdr()  { printf '\n%s%s%s\n' "$C_B" "$1" "$C_Z"; }
# ck "përshkrim" "si ta rregulloni" komandë args…   (✓ nëse komanda kthen 0, ✗ ndryshe)
ck()   { local d=$1 h=$2; shift 2; if "$@" >/dev/null 2>&1; then ok "$d"; else bad "$d" "$h"; fi; }
# cks: njësoj, por dështimi është soft (! ose ✗ me --strict)
cks()  { local d=$1 h=$2; shift 2; if "$@" >/dev/null 2>&1; then ok "$d"; else soft "$d (nuk u gjet)" "$h"; fi; }

summary() { # $1 = emri i fazës
  printf '\n%s: %d ✓, %d ✗, %d !\n' "$1" "$OK" "$FAIL" "$WARN"
  if [ "$FAIL" -eq 0 ]; then
    echo "Gjithçka që kontrollohet automatikisht është në rregull. Rubrika vlerëson edhe cilësinë, jo vetëm ekzistencën."
  else
    echo "Rregulloni ✗ para tag-ut. Ky skript kontrollon vetëm gjëra të dukshme; nuk jep pikë."
  fi
  [ "$FAIL" -gt 99 ] && FAIL=99
  exit "$FAIL"
}

# ---------- pastrim (docker / kubectl / temp) ----------
TMPD=$(mktemp -d 2>/dev/null || echo "/tmp/cec104chk-$$"); mkdir -p "$TMPD"
CPROJ="cec104check-$$"; COMPOSE_UP=0; COMPOSE_ARGS=(); NS_LIST=""
cleanup() {
  if [ "$COMPOSE_UP" = 1 ]; then docker compose -p "$CPROJ" "${COMPOSE_ARGS[@]}" down -v --remove-orphans --timeout 10 >/dev/null 2>&1; COMPOSE_UP=0; fi
  if [ -n "$NS_LIST" ]; then local n; for n in $NS_LIST; do kubectl delete namespace "$n" --wait=false >/dev/null 2>&1; done; NS_LIST=""; fi
  rm -rf "$TMPD"
}
trap cleanup EXIT
trap 'exit 130' INT TERM

# ---------- rrënja e repos ----------
if [ -n "${REPO:-}" ] && [ ! -d "$REPO" ]; then echo "REPO=$REPO nuk është dosje."; exit 99; fi
cd "${REPO:-.}" || exit 99
if [ ! -d services ]; then
  warn "nuk u gjet dosja services/ këtu ($(pwd)): ekzekutoni nga rrënja e repos tuaj ose REPO=/rruga bash $0"
fi

# ---------- ndihmës për fajlla ----------
has_file_glob() { local p; for p in "$@"; do compgen -G "$p" >/dev/null 2>&1 && return 0; done; return 1; }
list_files()    { local p; for p in "$@"; do compgen -G "$p" 2>/dev/null; done; }
first_file()    { local f; f=$(list_files "$@" | head -1); [ -n "$f" ] && { echo "$f"; return 0; }; return 1; }
nonempty()      { [ -s "$1" ]; }
words()         { wc -w < "$1" 2>/dev/null | tr -d ' '; }

GREP_EXCL=(--exclude-dir=.git --exclude-dir=node_modules --exclude-dir=.venv --exclude-dir=venv --exclude-dir=vendor
  --exclude-dir=target --exclude-dir=dist --exclude-dir=build --exclude-dir=__pycache__ --exclude-dir=.next
  --exclude-dir=.pytest_cache --exclude='*.lock' --exclude='package-lock.json')
# grep_any REGEX path… : True nëse ndonjë rresht në ndonjë fajll (rekursivisht) përputhet (pa dallim shkronjash)
grep_any() {
  local re=$1; shift; local t=() p
  for p in "$@"; do [ -e "$p" ] && t+=("$p"); done
  [ ${#t[@]} -gt 0 ] || return 1
  grep -rIqiE "${GREP_EXCL[@]}" -e "$re" -- "${t[@]}" 2>/dev/null
}
# code_has REGEX : kërkon në kodin e shërbimeve (jo në teste, jo në .md)
code_has() {
  local re=$1 t=() p
  for p in services libs lib shared common pkg internal; do [ -d "$p" ] && t+=("$p"); done
  [ ${#t[@]} -gt 0 ] || return 1
  grep -rIqiE "${GREP_EXCL[@]}" --exclude-dir=tests --exclude-dir=test --exclude-dir=__tests__ --exclude-dir=spec \
    --exclude='*.md' --exclude='test_*' --exclude='*_test.*' --exclude='*.test.*' --exclude='*.spec.*' \
    -e "$re" -- "${t[@]}" 2>/dev/null
}
# count_lines REGEX file : numri i rreshtave që përputhen
count_lines() { grep -ciE -e "$1" "$2" 2>/dev/null || true; }

services()       { local d; [ -d services ] || return 0; for d in services/*/; do [ -d "$d" ] && basename "$d"; done; }
count_services() { services | wc -l | tr -d ' '; }

# ---------- Markdown ----------
# md_rows FILE : numri i rreshtave të të dhënave në tabelat Markdown (pa titullin dhe ndarësin)
md_rows() { awk '/^[ \t]*\|/ { if ($0 ~ /^[ \t]*\|[ \t:|-]+\|?[ \t]*$/) { sep++; next } n++ } END { r = n - sep; print (r > 0 ? r : 0) }' "$1" 2>/dev/null; }
md_items() { grep -cE '^[ \t]*([-*+]|[0-9]+[.)])[ \t]+\S' "$1" 2>/dev/null || true; }
# placeholder-ët e shablloneve (starter-repo)
has_template_text() { grep -qiE 'plotësohet nga ekipi|plotesohet nga ekipi|lorem ipsum|<plotëso|TODO: plot' "$@" 2>/dev/null; }
has_diagram() { grep -qE '^[ \t]*```[ \t]*(mermaid|plantuml)|!\[[^]]*\]\([^)]+\)|<img |\.(png|svg|drawio|jpe?g)' "$1" 2>/dev/null; }

# ---------- compose ----------
compose_file() { first_file compose.yaml compose.yml docker-compose.yml docker-compose.yaml; }
compose_all()  { list_files 'compose*.y*ml' 'docker-compose*.y*ml' | sort -u; }
compose_services() { # emrat e shërbimeve nën "services:"
  [ -f "$1" ] || return 1
  awk '
    /^services:[ \t]*(#.*)?$/ { s=1; next }
    s && /^[^ \t#]/ { s=0 }
    s && /^[ \t]+[A-Za-z0-9_.-]+:[ \t]*(#.*)?$/ {
      match($0, /^[ \t]+/); ind=RLENGTH
      if (base==0 || ind<=base) { base=ind; n=$0; sub(/^[ \t]+/,"",n); sub(/:.*/,"",n); print n }
    }' "$1"
}
compose_svc_block() { # $1 = fajlli compose, $2 = emri i shërbimit: rreshtat e bllokut të tij
  awk -v s="$2" '
    /^services:[ \t]*(#.*)?$/ { sv=1; next }
    sv && /^[^ \t#]/ { sv=0; on=0 }
    sv && /^[ \t]+[A-Za-z0-9_.-]+:[ \t]*(#.*)?$/ {
      match($0, /^[ \t]+/); ind=RLENGTH
      if (base==0 || ind<=base) { base=ind; n=$0; sub(/^[ \t]+/,"",n); sub(/:.*/,"",n); on=(n==s) }
    }
    sv && on { print }' "$1"
}
compose_anchor_healthcheck() { # a ka ndonjë bllok x-… me ankor që përmban healthcheck (për <<: *ankor)
  awk '/^x-[A-Za-z0-9_.-]*:/ { x=1; next } x && /^[^ \t#]/ { x=0 } x && /^[ \t]+healthcheck:/ { f=1 } END { exit !f }' "$1"
}
# service_healthcheck SHËRBIMI : healthcheck në compose (blloku, ankor) ose HEALTHCHECK në Dockerfile
service_healthcheck() {
  local x=$1 C n b D; C=$(compose_file)
  D=$(dockerfile_of "$x"); [ -n "$D" ] && grep -qiE '^[ \t]*HEALTHCHECK[ \t]' "$D" && return 0
  [ -n "$C" ] || return 1
  for n in $(compose_services "$C"); do
    case "$n" in *"$x"*) ;; *) compose_svc_block "$C" "$n" | grep -q "services/$x" || continue ;; esac
    b=$(compose_svc_block "$C" "$n")
    printf '%s\n' "$b" | grep -qE '^[ \t]+healthcheck:' && return 0
    printf '%s\n' "$b" | grep -qE '^[ \t]+<<:' && compose_anchor_healthcheck "$C" && return 0
  done
  return 1
}
compose_args() { # argumentet e -f/--env-file për docker compose
  COMPOSE_ARGS=(-f "$(compose_file)")
  [ ! -f .env ] && [ -f .env.example ] && COMPOSE_ARGS+=(--env-file .env.example)
}
compose_has_broker() { local f; for f in $(compose_all); do grep -qiE 'image:.*(rabbitmq|nats|redis|kafka|redpanda|valkey)' "$f" && return 0; done; return 1; }
compose_grep() { local f; for f in $(compose_all); do grep -qiE -e "$1" "$f" && return 0; done; return 1; }

# ---------- Kubernetes (yaml-ish, pa yq) ----------
k8s_dirs() { local d; for d in k8s deploy/k8s manifests kubernetes deploy/kubernetes infra/k8s; do [ -d "$d" ] && echo "$d"; done; }
k8s_files() { local d; for d in $(k8s_dirs); do find -L "$d" -type f \( -name '*.yaml' -o -name '*.yml' \) 2>/dev/null; done | sort; }
K8S_DOCS_CACHE=""
# k8s_docs: një rresht për dokument: kind<TAB>emri<TAB>fajlli<TAB>imazhet<TAB>flamuj(readiness,liveness,requests,limits,nonroot)<TAB>namespace
k8s_docs() {
  if [ -z "$K8S_DOCS_CACHE" ]; then
    local files; files=$(k8s_files)
    if [ -n "$files" ]; then
      # shellcheck disable=SC2086
      K8S_DOCS_CACHE=$(echo "$files" | tr '\n' '\0' | xargs -0 awk '
        function flush() {
          if (kind != "") printf "%s\t%s\t%s\t%s\t%d%d%d%d%d\t%s\n", kind, name, fname, img, rp, lp, rq, lm, nr, ns
          kind=""; name=""; img=""; ns=""; rp=0; lp=0; rq=0; lm=0; nr=0; meta=0
        }
        function val(s) { sub(/^[ \t-]*[A-Za-z]+:[ \t]*/, "", s); sub(/[ \t]+#.*$/, "", s); gsub(/["\047]/, "", s); sub(/[ \t]+$/, "", s); return s }
        FNR==1 { flush(); fname=FILENAME }
        /^---/ { flush(); next }
        /^kind:/ { kind=val($0); next }
        /^metadata:/ { meta=1; next }
        meta && /^[^ \t#]/ { meta=0 }
        meta && name=="" && /^[ \t]+name:/ { name=val($0); next }
        meta && /^[ \t]+namespace:/ { ns=val($0); next }
        /^[ \t-]*image:/ { img = img " " val($0) }
        /readinessProbe:/ { rp=1 }
        /livenessProbe:/ { lp=1 }
        /^[ \t]*requests:/ { rq=1 }
        /^[ \t]*limits:/ { lm=1 }
        /runAsNonRoot:[ \t]*true/ { nr=1 }
        END { flush() }' 2>/dev/null)
    fi
    [ -n "$K8S_DOCS_CACHE" ] || K8S_DOCS_CACHE="-"
  fi
  [ "$K8S_DOCS_CACHE" = "-" ] || printf '%s\n' "$K8S_DOCS_CACHE"
}
# k8s_find KIND SHËRBIMI : dokumentet e llojit KIND që i përkasin shërbimit (emri, imazhi ose fajlli e përmban emrin)
k8s_find() {
  k8s_docs | awk -F'\t' -v k="$(printf '%s' "$1" | tr 'A-Z' 'a-z')" -v s="$(printf '%s' "$2" | tr 'A-Z' 'a-z')" \
    'tolower($1)==k && (index(tolower($2),s) || index(tolower($4),s) || index(tolower($3),s))'
}
k8s_kind_count() { k8s_docs | awk -F'\t' -v k="$(printf '%s' "$1" | tr 'A-Z' 'a-z')" 'tolower($1)==k {n++} END {print n+0}'; }
k8s_has_kind() { [ "$(k8s_kind_count "$1")" -gt 0 ]; }
# flamuri i dokumentit: pozicioni 1=readiness 2=liveness 3=requests 4=limits 5=runAsNonRoot
k8s_flag() { # $1 = rreshti nga k8s_find, $2 = pozicioni
  printf '%s' "$1" | awk -F'\t' -v p="$2" '{print substr($5,p,1)}'
}

# ---------- workflows ----------
workflows() { list_files '.github/workflows/*.yml' '.github/workflows/*.yaml'; }
wf_has() { local f; for f in $(workflows); do grep -qiE -e "$1" "$f" && return 0; done; return 1; }
wf_tabs() { local f; for f in $(workflows); do grep -qP '^\t' "$f" 2>/dev/null && return 0; done; return 1; }

# ---------- git ----------
git_root_here() { git rev-parse --git-dir >/dev/null 2>&1 && [ "$(git rev-parse --show-toplevel 2>/dev/null)" = "$(pwd -P)" ]; }
tag_check() { # $1 = f1..f7
  if ! git_root_here; then
    soft "kjo dosje nuk është rrënja e një repoje Git: tag-u $1 nuk u kontrollua" "git init, commit, pastaj git tag $1 && git push origin $1"
    return
  fi
  if git rev-parse -q --verify "refs/tags/$1" >/dev/null 2>&1; then
    ok "tag-u $1 ekziston ($(git log -1 --format=%cd --date=short "$1" 2>/dev/null))"
    if [ "$(git rev-parse "$1^{commit}" 2>/dev/null)" != "$(git rev-parse HEAD 2>/dev/null)" ]; then
      warn "tag-u $1 nuk tregon te commit-i aktual (HEAD); në rregull nëse nuk synoni ta dorëzoni gjendjen e re"
    fi
  else
    soft "tag-u $1 nuk ekziston ende (git tag $1 && git push origin $1)" "git tag $1 && git push origin $1 (me shkronja të vogla)"
  fi
}
git_tracked() { git_root_here && git ls-files --error-unmatch "$1" >/dev/null 2>&1; }

# ---------- ditari ----------
chk_journal() { # $1 = f1..f7
  local f="docs/journal/$1.md" w
  if [ ! -s "$f" ]; then
    bad "$f ekziston (Ditari i inxhinierit, kopja në repo)" "krijoni $f: numrat që matët, vendimet, ku gaboi AI-ja (1–2 faqe)"
    return
  fi
  w=$(words "$f")
  if [ "${w:-0}" -lt 80 ]; then bad "$f është shumë i shkurtër ($w fjalë; duhen të paktën 80)" "shkruani 1–2 faqe: matjet tuaja, vendimet, gabimet e AI-së"
  else ok "$f ekziston ($w fjalë)"; fi
  grep -qE '[0-9]' "$f" && ok "$f përmban numra (matje)" || soft "$f nuk përmban asnjë numër të matur" "shtoni numrat që matët vetë (ms, %, kërkesa/s…)"
}

# ---------- shërbimet: ndihmës të përbashkët ----------
svc_has_manifest() { # ka fajll ndërtimi/varësish në rrënjën e shërbimit
  local d="services/$1"
  has_file_glob "$d/Dockerfile*" "$d/package.json" "$d/go.mod" "$d/pom.xml" "$d/build.gradle*" "$d/requirements*.txt" \
    "$d/pyproject.toml" "$d/*.csproj" "$d/Cargo.toml" "$d/Gemfile" "$d/composer.json" "$d/*/*.csproj"
}
svc_has_source() { # ka të paktën një fajll kodi
  [ -n "$(find "services/$1" \( -name node_modules -o -name .venv -o -name __pycache__ \) -prune -o -type f \
    \( -name '*.py' -o -name '*.js' -o -name '*.ts' -o -name '*.go' -o -name '*.java' -o -name '*.kt' -o -name '*.cs' -o -name '*.rb' -o -name '*.rs' -o -name '*.php' -o -name '*.mjs' \) -print 2>/dev/null | head -1)" ]
}
svc_openapi() { # fajlli OpenAPI i shërbimit $1 (kontrata)
  first_file "contracts/$1.openapi.*" "contracts/$1.*" "contracts/*$1*.openapi.*" "contracts/*$1*" "contracts/$1/*" \
    "services/$1/openapi.*" "services/$1/openapi/*" "services/$1/docs/openapi.*" "services/$1/*openapi*" "services/$1/api/openapi.*" "services/$1/contracts/*"
}
is_openapi() { # fajll YAML/JSON që duket OpenAPI/Swagger
  grep -qiE '"?(openapi|swagger)"?[ \t]*:' "$1" 2>/dev/null && grep -qiE '"?paths"?[ \t]*:' "$1" 2>/dev/null
}

# ---------- Dockerfile ----------
# dockerfile_of SHËRBIMI : Dockerfile kryesor
dockerfile_of() { first_file "services/$1/Dockerfile" "services/$1/Dockerfile.*" "services/$1/*/Dockerfile" "services/$1/docker/Dockerfile"; }
dockerfile_user() { # USER-i i fundit
  grep -iE '^[ \t]*USER[ \t]+' "$1" | tail -1 | awk '{print $2}'
}
dockerfile_latest() { # imazhe me :latest ose pa tag (ARG, scratch, fazat e mëparshme përjashtohen); printon shkelësit
  awk '
    tolower($0) ~ /^[ \t]*from[ \t]+/ {
      line=$0; sub(/^[ \t]*[Ff][Rr][Oo][Mm][ \t]+/, "", line)
      while (line ~ /^--[A-Za-z-]+(=[^ \t]+)?[ \t]+/) sub(/^--[A-Za-z-]+(=[^ \t]+)?[ \t]+/, "", line)
      split(line, a, /[ \t]+/); img=a[1]
      stage=""; if (tolower(a[2])=="as") stage=tolower(a[3])
      lower=tolower(img)
      if (lower=="scratch" || img ~ /^\$/ || (lower in stages) || img ~ /@sha256:/) { }
      else if (img ~ /:latest$/) print img
      else { n=split(img, p, "/"); last=p[n]; if (last !~ /:/) print img " (pa tag)" }
      if (stage != "") stages[stage]=1
    }' "$1"
}

# ---------- sekrete ----------
SECRET_RE='AKIA[0-9A-Z]{16}|-----BEGIN [A-Z ]*PRIVATE KEY-----|gh[pousr]_[A-Za-z0-9]{36,}|github_pat_[A-Za-z0-9_]{40,}|xox[baprs]-[A-Za-z0-9-]{10,}|sk-[A-Za-z0-9]{32,}|AIza[0-9A-Za-z_-]{35}|glpat-[A-Za-z0-9_-]{20,}'
secret_scan() { # printon fajllat e dyshimtë (të ndjekur nga Git, ose të gjithë nëse s'ka Git)
  local list
  if git_root_here; then list=$(git ls-files 2>/dev/null); else list=$(find . -type f -not -path './.git/*' -not -path '*/node_modules/*' -not -path '*/.venv/*' 2>/dev/null | sed 's|^\./||'); fi
  [ -n "$list" ] || return 0
  printf '%s\n' "$list" | grep -vE '(\.example$|\.sample$|\.lock$|package-lock\.json$|\.(png|jpe?g|gif|pdf|ico|woff2?|zip|gz|mp4)$)' \
    | tr '\n' '\0' | xargs -0 grep -IlE -e "$SECRET_RE" 2>/dev/null | head -5
}

# ---------- build (--build) ----------
HEALTH_PATHS="/health /healthz /health/ready /readyz /ready /actuator/health /api/health"
curl_ok() { local u=$1; if command -v curl >/dev/null 2>&1; then curl -fsS -m 3 -o /dev/null "$u" 2>/dev/null; else wget -q -T 3 -O /dev/null "$u" 2>/dev/null; fi; }
mem_avail_mb() { awk '/MemAvailable/ {printf "%d", $2/1024}' /proc/meminfo 2>/dev/null; }
BUILD_DONE=0
build_checks() {
  [ "$BUILD" = 1 ] || return 0
  [ "$BUILD_DONE" = 1 ] && return 0
  BUILD_DONE=1
  hdr "Build (--build): docker compose up --build --wait + /health"
  local C; C=$(compose_file)
  if [ -z "$C" ]; then bad "compose.yaml ekziston (pa të s'ka çfarë të nisim)" "krijoni compose.yaml (ose compose.yml / docker-compose.yml) në rrënjë"; return; fi
  if ! command -v docker >/dev/null 2>&1 || ! docker info >/dev/null 2>&1; then warn "Docker nuk është i disponueshëm: --build u anashkalua"; return; fi
  if ! docker compose version >/dev/null 2>&1; then warn "'docker compose' nuk është i instaluar: --build u anashkalua"; return; fi
  local m; m=$(mem_avail_mb)
  if [ -n "$m" ] && [ "$m" -lt 2048 ]; then warn "RAM e lirë ${m} MB (< 2048): --build u anashkalua"; return; fi
  compose_args
  if ! docker compose "${COMPOSE_ARGS[@]}" config -q >/dev/null 2>"$TMPD/cfg.err"; then
    if [ ! -f .env ] && [ -f .env.example ]; then
      warn "compose kërkon variabla nga .env (mungon): cp .env.example .env, plotësoni vlerat dhe provoni sërish; --build u anashkalua"; return
    fi
    bad "docker compose config është valid" "ekzekutoni 'docker compose config' dhe lexoni gabimin: $(head -c 160 "$TMPD/cfg.err" | tr '\n' ' ')"
    return
  fi
  ok "docker compose config është valid"
  COMPOSE_UP=1
  if docker compose -p "$CPROJ" "${COMPOSE_ARGS[@]}" up --build --wait --wait-timeout 300 -d >"$TMPD/up.log" 2>&1; then
    ok "docker compose up --build --wait: të gjitha shërbimet janë ngritur"
  else
    bad "docker compose up --build --wait dështoi" "provoni lokalisht 'docker compose up --build' dhe lexoni logun; porti i zënë? healthcheck që s'bëhet healthy? Fundi i logut: $(tail -n 3 "$TMPD/up.log" | tr '\n' ' ' | head -c 300)"
    return
  fi
  local pubs svc ports p path found s
  pubs=$(docker compose -p "$CPROJ" "${COMPOSE_ARGS[@]}" ps --format '{{.Service}}|{{range .Publishers}}{{.PublishedPort}},{{end}}' 2>/dev/null)
  for s in $(services); do
    ports=$(printf '%s\n' "$pubs" | awk -F'|' -v s="$s" 'index(tolower($1), tolower(s)) {print $2}' | tr ',' '\n' | grep -E '^[1-9][0-9]*$' | sort -u)
    if [ -z "$ports" ]; then warn "$s: asnjë port i publikuar në compose, /health nuk u provua nga jashtë"; continue; fi
    found=""
    for _ in 1 2 3 4 5 6; do   # deri ~6 raunde, secili provon të gjitha rrugët
      for p in $ports; do for path in $HEALTH_PATHS; do
        curl_ok "http://127.0.0.1:$p$path" && { found="$p$path"; break 3; }
      done; done
      sleep 1
    done
    [ -n "$found" ] && ok "$s: përgjigjet në 127.0.0.1:$found" || bad "$s: nuk përgjigjet te /health (porte: $(echo $ports | tr '\n' ' '))" "shtoni endpoint-in GET /health që kthen 200"
  done
  docker compose -p "$CPROJ" "${COMPOSE_ARGS[@]}" down -v --remove-orphans --timeout 10 >/dev/null 2>&1 && COMPOSE_UP=0
  [ "$COMPOSE_UP" = 0 ] && ok "docker compose down: pastrim i kryer"
}

# ---------- cluster (--cluster) ----------
CLUSTER_DONE=0
cluster_checks() {
  [ "$CLUSTER" = 1 ] || return 0
  [ "$CLUSTER_DONE" = 1 ] && return 0
  CLUSTER_DONE=1
  hdr "Cluster (--cluster): aplikim i manifesteve + rollout"
  if [ -z "$(k8s_dirs)" ]; then bad "ka dosje me manifeste Kubernetes (k8s/, deploy/k8s/, manifests/, kubernetes/)" "vendosni manifestet te k8s/ ose deploy/k8s/"; return; fi
  if ! command -v kubectl >/dev/null 2>&1; then warn "kubectl nuk është i instaluar: --cluster u anashkalua"; return; fi
  local ctx srv
  ctx=$(kubectl config current-context 2>/dev/null)
  if [ -z "$ctx" ]; then warn "asnjë kontekst kubectl (s'ka cluster): --cluster u anashkalua"; return; fi
  srv=$(kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}' 2>/dev/null)
  case "$srv" in
    https://127.0.0.1:*|https://localhost:*|https://\[::1\]:*|http://127.0.0.1:*|http://localhost:*) ;;
    *) warn "konteksti '$ctx' nuk është cluster lokal (server: ${srv:-?}): anashkalohet për siguri"; return ;;
  esac
  if ! kubectl --request-timeout=5s get ns >/dev/null 2>&1; then warn "cluster-i '$ctx' nuk përgjigjet: --cluster u anashkalua"; return; fi
  # namespace-t e deklaruara në manifeste (nëse ka); përndryshe përdoret një namespace i përkohshëm
  local declared n NSARGS=() tmpns="cec104check-$$"
  declared=$(k8s_docs | awk -F'\t' '{ if ($6 != "") print $6; if (tolower($1) == "namespace" && $2 != "") print $2 }' | sort -u)
  if [ -n "$declared" ]; then
    for n in $declared; do
      if kubectl get namespace "$n" >/dev/null 2>&1; then
        warn "namespace '$n' ekziston tashmë në cluster: --cluster nuk e prek; fshijeni ose provoni vetë kubectl apply"; return
      fi
    done
    for n in $declared; do kubectl create namespace "$n" >/dev/null 2>&1 && NS_LIST="$NS_LIST $n"; done
  else
    kubectl create namespace "$tmpns" >/dev/null 2>&1 || { warn "nuk u krijua namespace i përkohshëm: --cluster u anashkalua"; return; }
    NS_LIST="$tmpns"; declared="$tmpns"; NSARGS=(-n "$tmpns")
  fi
  local d out=0
  for d in $(k8s_dirs); do
    if [ -f "$d/kustomization.yaml" ] || [ -f "$d/kustomization.yml" ]; then kubectl apply "${NSARGS[@]}" -k "$d" >"$TMPD/apply.log" 2>&1 || out=1
    else kubectl apply "${NSARGS[@]}" -R -f "$d" >"$TMPD/apply.log" 2>&1 || out=1; fi
  done
  if [ "$out" = 0 ]; then ok "kubectl apply i manifesteve (namespace: $(echo $declared), kontekst $ctx)"
  else bad "kubectl apply i manifesteve" "ekzekutoni kubectl apply -R -f <dosja> dhe lexoni gabimin: $(tail -n 2 "$TMPD/apply.log" | tr '\n' ' ' | head -c 250)"; return; fi
  local any=0 waited=0
  for n in $declared; do
    [ -n "$(kubectl get deploy -n "$n" -o name 2>/dev/null)" ] || continue
    any=1
    kubectl wait -n "$n" --for=condition=available deployment --all --timeout=180s >"$TMPD/wait.log" 2>&1 || waited=1
  done
  if [ "$any" = 0 ]; then warn "asnjë Deployment u krijua"
  elif [ "$waited" = 0 ]; then ok "rollout: të gjitha Deployment-et janë available"
  else bad "rollout: Deployment-et bëhen available brenda 180 s" "imazhet duhen të jenë të ngarkuara në cluster (kind load docker-image …) ose të tërhiqen nga GHCR; shihni: kubectl get pods -A, kubectl describe pod"; fi
  for n in $NS_LIST; do kubectl delete namespace "$n" --wait=false >/dev/null 2>&1; done
  NS_LIST=""; ok "namespace-t e përkohshme u fshinë"
}

# ---------- dokumente të përbashkëta ----------
doc_first() { first_file "$@"; }
