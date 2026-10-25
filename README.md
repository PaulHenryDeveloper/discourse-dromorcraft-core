# DromorCraft core

Discourse plugin of the [DromorCraft community forum](https://forum.dromorcraft.com). It turns the support form templates into structured data about the [DromorCraft launcher](https://dromorcraft.com): launcher and Minecraft versions, system and loader, editable by the topic's author and staff. A card above the first post shows that data with links to the site's resource pages, and topics reported on an old launcher get a notice pointing to the download page.

> **Status:** 0.5.1, extraction, editing, the support card and the outdated-version notice. `dromorcraft_core_enabled` is off by default.

## Settings

| Setting | Default | What it does |
| --- | --- | --- |
| `dromorcraft_core_enabled` | off | Turns the plugin on. |
| `dromorcraft_core_support_categories` | empty | Categories whose new topics are read (on the forum: Support › Help and Support › Launcher bugs). |
| `dromorcraft_core_outdated_notice` | on | Puts the outdated-version notice on new support topics. |

## Extraction

When a regular topic is created in one of the support categories, the plugin fills four topic custom fields:

| Field | Source | Accepted values |
| --- | --- | --- |
| `dc_launcher_version` | "Launcher version" in the first post | `^[0-9]{1,3}(\.[0-9]{1,3}){1,3}$`, at most 15 characters |
| `dc_mc_version` | "Minecraft version" in the first post | same |
| `dc_os` | the topic's tags | `windows`, `linux` (only when exactly one is set) |
| `dc_loader` | the topic's tags | `vanilla`, `fabric`, `quilt`, `forge`, `neoforge` (only when exactly one is set) |

- A value that doesn't match is left out; nothing is stored as typed.
- A field the post doesn't have is left out.
- Personal messages and other categories are ignored.
- If extraction raises, the error is logged and the topic is created as usual.

The fields are read once, on `topic_created`; editing the post later doesn't change them. To change them, use the endpoint below.

## Known versions and the outdated notice

An hourly job (`Jobs::DromorcraftCore::RefreshKnownVersions`) reads the public [releases feed](https://github.com/PaulHenryDeveloper/DromorCraft-releases/releases.atom), with no token.

- The URL is fixed in the code, not a setting.
- Only tags that are plain versions (`v1.4.24`) count; pre-releases and anything else are left out.
- The feed lists only the latest releases, so each run adds to the stored list (in `PluginStore`, newest first, at most 100) instead of replacing it.
- If the feed is down, times out, answers with an error, is larger than 1 MB or isn't a feed, the previous list stays.

When a new support topic has a launcher version older than the newest known one, the first post gets a post notice (the same kind staff add with "Add staff notice") with a link to `https://dromorcraft.com/download/`. Nothing is posted as a reply, so the topic isn't bumped and still counts as unanswered. The notice replaces the automatic first-post notices (new or returning user) but never one written by staff. A version newer than the latest known, or no known versions yet, means no notice. The plugin shows its own notice with an info icon on the neutral background of the support card, instead of the staff shield and danger background core uses for custom notices; staff notices keep that look.

## Support card

Support topics with stored data show a card above the first post (outlet `topic-above-posts`): launcher, Minecraft, system and loader, each only when present.

- The data comes from the topic view (`dromorcraft_support`), sent only for topics in the support categories while the plugin is on. Values are checked against the same patterns and allowlists again before they are sent.
- An outdated launcher gets an "Update to x.y.z" link to `https://dromorcraft.com/download/`.
- "Might help" links to pages under `https://dromorcraft.com/resources/`: Launcher updates (outdated launcher only), Common errors, Java versions, and Loaders and mod compatibility (Fabric, Quilt, Forge or NeoForge only). English URLs; the site sends visitors to their own language.
- Labels are in English and Brazilian Portuguese (`config/locales/client.*.yml`). Colors come only from the palette variables, so the card follows the light and dark schemes.

## Editing the fields

`PUT /dromorcraft-core/topics/:topic_id/support` with any of `launcher_version`, `minecraft_version`, `os` and `loader`. A blank value clears the field.

| Who | Result |
| --- | --- |
| Not logged in | 403 |
| Can see the topic but isn't its author or staff | 403 |
| The author, while the topic isn't archived | 200 |
| Staff (moderators and admins), always | 200, logged in the staff action log as `dromorcraft_support_edit` |
| Topic outside the support categories, or one the user can't see | 404 |

- The rule lives in the guardian (`can_edit_dromorcraft_support?`), and the topic view sends it as `dromorcraft_support.can_edit`.
- Values are checked with the same pattern and allowlists as extraction. One bad value is a 400, and nothing is saved.
- Authors get at most 10 edits a minute.
- A changed launcher version refreshes the outdated notice: rewritten for another old version, removed for the latest. A notice written by staff is left alone.

There is no edit button in the forum yet; the endpoint is the contract for it.

## Planned
- **Edit button** on the support card for the author and staff, using the endpoint above.

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

QUnit tests live in `test/javascripts`; system specs (Playwright) in `spec/system`.

Ruby specs run inside a Discourse checkout: `LOAD_PLUGINS=1 bin/rspec plugins/discourse-dromorcraft-core/spec`.

## License

MIT, see [LICENSE](LICENSE).
