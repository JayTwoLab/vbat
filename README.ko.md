# vbat

> [English](README.md)

`bat`의 래퍼 스크립트로, 와일드카드와 다양한 문자 인코딩을 지원하여 텍스트 파일을 플랫폼 간에 보기 쉽게 만듭니다.

지원 스크립트
- `vbat.bat` — Windows(CMD) 호출하는 실행기
- `vbat.sh`  — POSIX 셸 스크립트 (Linux/macOS)

필수 구성 요소
- `bat`(파일 하이라이트형 페이저)가 `PATH`에 설치되어 있어야 합니다.
   - A cat(1) clone with wings. https://github.com/sharkdp/bat
   
간단 사용법
- Windows (CMD):
  - `vbat.bat myfile.txt`
- Bash (Linux/macOS):
  - `vbat.sh myfile.txt`

옵션
- `--encoding=값` 또는 `-e 값` — 파일 인코딩을 강제 지정합니다 (예: `UTF-8`, `CP949`, `EUC-KR`).
- `-h` 또는 `--help` — 도움말 표시.

`.encoding` 사이드카 파일
각 대상 텍스트 파일과 같은 이름에 확장자 `.encoding`을 붙인 파일을 두면, 다음과 같은 형식으로 인코딩을 지정할 수 있습니다:
```
encoding=UTF8
```

우선순위는 `--encoding` 인자 → `.encoding` 사이드카 → 스크립트 기본값 순서입니다. (PowerShell/CMD 계열은 기본값이 CP949, 셸 스크립트는 기본값이 UTF-8)

예시
- 특정 파일을 UTF-8로 보기:
  - `vbat.sh myfile.txt --encoding=UTF-8`
- 짧은 플래그 사용 예:
  - `vbat.bat myfile.txt -e CP949`
 
- `bat`이 `PATH`에 있는지 확인하세요.
