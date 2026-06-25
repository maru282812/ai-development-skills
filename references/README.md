# References

このフォルダは、複数 skill から参照する横断資料や設計メモの置き場です。

skill 本文はここには置かず、以下を canonical とします。

- 汎用 skill: `.skills/<skill-name>/SKILL.md`
- Claude Code 専用 skill: `.claude/skills/<skill-name>/SKILL.md`

`system-investigator` の本文は `.skills/system-investigator/SKILL.md` を参照してください。

## 置いてよいもの

- 複数 skill で共有する用語集
- profile 設計のメモ
- skill 間の連携方針
- プロジェクトへコピーしない背景資料

## 置かないもの

- 個別 skill の本文
- 特定 skill だけが使う参考資料
- 特定プロジェクト固有の要件・素材・参考サイト

個別 skill だけが使う資料は `.skills/<skill-name>/references/` に置きます。
