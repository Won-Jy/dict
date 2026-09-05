# 개인 단어장

영어 · 프랑스어 · 독일어 단어와 표현을 모으는 개인 사전.
GitHub Pages에 올려두면 핸드폰과 컴퓨터에서 같은 데이터를 봅니다.

파일:
```
index.html          앱 전체 (HTML + CSS + JS)
supabase-setup.sql  데이터베이스 초기 설정
manifest.json       홈 화면 추가용
sw.js               앱 껍데기 캐시
icon-192.png
icon-512.png
```

---

## 설치 (한 번만)

### 1. Supabase 프로젝트

1. [supabase.com](https://supabase.com) 가입 → **New project**
   Region은 `West EU (Ireland)`나 `Central EU (Frankfurt)`가 프랑스에서 가장 빠릅니다.
2. **SQL Editor** → `supabase-setup.sql` 내용 전체 붙여넣기 → **Run**
   테이블 3개, 접근 권한, 녹음 저장소가 한 번에 만들어집니다.
3. **Authentication → Users → Add user**
   이메일과 비밀번호를 정하고 **Auto Confirm User**를 켜 주세요.
   (앱에 가입 화면은 없습니다. 쓰는 사람이 본인 한 명이라서요.)
4. **Project Settings → API**에서 두 값을 복사:
   - Project URL
   - `anon` `public` 키

### 2. 앱에 값 넣기

`index.html`을 열고 `<script type="module">` 바로 아래 세 줄을 고칩니다.

```js
const CONFIG = {
  SUPABASE_URL:      'https://xxxxx.supabase.co',
  SUPABASE_ANON_KEY: 'eyJhbGci...',
  TRASH_DAYS: 30,
};
```

`anon` 키는 공개되어도 괜찮은 키입니다. 실제 접근 권한은 로그인과
데이터베이스 규칙(RLS)이 막습니다. 본인 계정으로 로그인한 사람만
본인 데이터를 읽고 씁니다.

### 3. GitHub Pages에 올리기

새 저장소를 만들고 (예: `Won-Jy/dict`) 다섯 파일을 `main` 브랜치 루트에 넣습니다.
Settings → Pages → Source를 `main` / `root`로. 1~2분 뒤
`won-jy.github.io/dict` 에서 열립니다.

**HTTPS여야 마이크가 열립니다.** GitHub Pages는 기본이 HTTPS라 그대로 됩니다.
파일을 더블클릭해서 `file://`로 여는 방식으로는 녹음도 동기화도 안 됩니다.

### 4. 홈 화면에 추가

- iPhone Safari: 공유 → 홈 화면에 추가
- Android Chrome: 메뉴 → 앱 설치

---

## 쓰는 법

**등록** — 언어 고르고 단어 치고 Enter. 그게 전부입니다.
저장하면 입력칸이 비워지고 커서가 남아 있어서 연달아 여러 개를
넣을 수 있어요. 이미 있는 단어면 저장 대신 그 항목으로 넘어갑니다.

**단어 페이지** — 모든 칸은 치는 대로 저장됩니다. 저장 버튼 없음.
화면 맨 위 가는 선이 잠깐 지나가면 저장된 겁니다.

**발음** — 녹음을 누르면 바로 시작하고, 다시 누르면 멈춥니다.
20초가 넘으면 알아서 끊깁니다. 2초짜리 발음이 대략 25KB라
무료 용량 1GB면 4만 개쯤 들어갑니다.

**연관어** — `+ 추가`를 누르고 단어를 칩니다.
이미 있는 단어면 아래에 뜨고, 없는 단어를 그냥 Enter로 넣으면
새 항목이 만들어지면서 연결됩니다.
연결은 **양쪽에 함께** 걸립니다. A의 동의어에 B를 넣으면
B의 동의어에도 A가 생기고, 한쪽에서 `×`로 끊으면 양쪽 다 끊깁니다.
언어를 바꿔서 연결할 수 있어서 `liberty`(EN) ↔ `liberté`(FR) 같은
어원 관계도 걸립니다.

**채우기** — 각 단어의 일곱 칸(의미 · 발음 · 어원 · 어원적 연관어 ·
동의어 · 반의어 · 예문) 중 비어 있는 게 있는 단어를 모아 보여줍니다.
위쪽 항목 버튼으로 "발음만 없는 단어"처럼 좁힐 수 있습니다.
탭에 붙은 붉은 숫자가 아직 덜 채워진 단어 수입니다.

목록에서 단어 오른쪽의 점 일곱 개도 같은 뜻입니다.
꽉 찬 점은 채워진 칸, 붉은 테두리의 빈 점은 비어 있는 칸.

**휴지통** — 삭제하면 30일 보관됩니다. 남은 날짜가 함께 보이고,
30일이 지난 항목은 앱을 열 때 녹음 파일까지 같이 지워집니다.
기간은 `CONFIG.TRASH_DAYS`에서 바꿀 수 있습니다.

---

## 알아둘 것

**언어 추가** — 지금은 en / fr / de 세 개입니다. 늘리려면 두 군데를 고칩니다.

```sql
-- Supabase SQL Editor
alter table public.entries drop constraint entries_lang_check;
alter table public.entries add constraint entries_lang_check
  check (lang in ('en','fr','de','it'));
```

```js
// index.html
const LANGS      = { en:'영어', fr:'프랑스어', de:'독일어', it:'이탈리아어' };
const LANG_SHORT = { en:'EN', fr:'FR', de:'DE', it:'IT' };
```

**오프라인** — 앱 화면은 캐시되지만 단어는 열 때마다 가져옵니다.
지하철에서는 안 열려요. 필요해지면 로컬 캐시를 붙일 수 있습니다.

**중복** — 같은 언어 안에서 같은 표제어는 하나만 됩니다(대소문자 무시).
언어가 다르면 같은 철자를 따로 둘 수 있습니다.

**무료 한도** — 데이터베이스 500MB, 파일 1GB.
글자만 따지면 단어 수만 개도 남습니다. 실질 한도는 녹음이에요.
Supabase 무료 프로젝트는 일주일 넘게 아무 요청이 없으면 잠자기로
들어가는데, 대시보드에서 바로 깨울 수 있습니다.

**백업** — Supabase 대시보드 Table Editor에서 각 테이블을 CSV로
내려받을 수 있습니다. 가끔 받아두면 마음이 편합니다.
```
