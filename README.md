# DromorCraft core

Discourse plugin of the [DromorCraft community forum](https://community.dromorcraft.com). It turns the support form templates into structured data about the [DromorCraft launcher](https://dromorcraft.com): launcher and Minecraft versions, system and loader.

> **Status:** skeleton (0.1.0). The setting `dromorcraft_core_enabled` is off by default and the plugin does nothing yet. The features below are planned.

## Planned

- **Extraction.** When a topic is created in Support › Help or Support › Launcher bugs, read the post the form template produced and store `dc_launcher_version`, `dc_mc_version`, `dc_os` and `dc_loader` as topic custom fields, with a strict charset and length. If extraction fails, the topic goes on as normal.
- **Known launcher versions.** A scheduled job reads the public [releases feed](https://github.com/PaulHenryDeveloper/DromorCraft-releases/releases.atom) (no token). A topic on an outdated version gets a notice linking to the download page. If the feed is down, the previous list stays.
- **Support card** above the first post, with the extracted data and links to the site's resources, readable in both palettes.
- **Edit permissions.** Only the author and staff edit the fields.

## Form template contract

The forum's form templates ("Launcher bug" and "Help request") are not part of this plugin. They are set up on the forum, and the plugin relies on their field ids and labels. The launcher prefills the fields by id; the plugin reads the post back by label. Changing either breaks one of them.

| Field id | Label | Type |
| --- | --- | --- |
| `launcher-version` | Launcher version | input, `^[0-9]{1,3}(\.[0-9]{1,3}){1,3}$`, required |
| `minecraft-version` | Minecraft version | input, same pattern |
| `what-happened` / `question` | What happened / What do you need help with | textarea, required |
| `steps` / `tried` | Steps to reproduce / What you already tried | textarea |
| `expected` | What you expected | textarea (bugs only) |
| `log` | Log | upload, `.log`/`.txt`, one file |

System and loader are not form fields. They come from the required tag groups System (`windows`, `linux`) and Loader (`vanilla`, `fabric`, `quilt`, `forge`, `neoforge`).

Prefill URL: `/new-topic?category=suporte/bugs&launcher-version=1.4.24&minecraft-version=1.21.1`.

### How the post is generated (spike, Discourse 2026.7)

The composer builds the post in the browser (`frontend/discourse/app/lib/form-template-validation.js`):

- each filled field becomes `### <label>`, a newline and the value, in template order;
- blocks are joined by a blank line, and empty fields are left out;
- an upload becomes `[<name>|attachment](upload://…) (<size>)`.

```markdown
### Launcher version
1.4.24

### Minecraft version
1.21.1

### What happened
The game closes right after the loading screen.

### Steps to reproduce
1. Create a Fabric instance
2. Click Play

### Log
[latest.log|attachment](upload://AbCdEf.log) (12.3 KB)
```

**Decision:** the format is deterministic enough. Labels come from the template and are not translated, order is fixed and the separator is fixed. No plan B (custom composer fields via `add_permitted_post_create_param`) is needed. The extractor:

- matches only the known labels, anchored at the start of a line, and takes the first match, since the version fields come first and a textarea may contain a `### Launcher version` line;
- takes only the first line under a version heading and validates it with the template's pattern;
- runs only on `topic_created`, because later edits are untrusted.

## Development

CI runs the official [`discourse-plugin.yml`](https://github.com/discourse/.github) workflow against the ESR the forum runs (`release/2026.7`) and against the newest monthly release (`release/2026.9`), and `d-compat-branch.yml` keeps compatibility branches.

```bash
pnpm install
pnpm lint
```

Ruby specs run inside a Discourse checkout: `LOAD_PLUGINS=1 bin/rspec plugins/discourse-dromorcraft-core/spec`.

## License

MIT, see [LICENSE](LICENSE).
