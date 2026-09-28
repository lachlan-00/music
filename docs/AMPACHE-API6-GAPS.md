# Ampache API 6 — gap analysis

Where the Music app's Ampache implementation stands against Ampache API version 6, and which of the
gaps are worth closing.

Reference used: the Ampache `develop` tree (Ampache 8, which serves API6 alongside 3/4/5/8).
In order of authority:

| Source | What it is good for |
|---|---|
| `src/Module/Api/Api6.php` | `METHOD_LIST` — the definitive action list |
| `src/Module/Api/Json6_Data.php` / `Xml6_Data.php` | the definitive field lists |
| `docs/api-responses/api6/json-responses/` | 244 captured real payloads — the fastest way to diff |
| `docs/openapi-6.json` | REST paths + `x-rpc-mappings`; **only 23 schemas**, so not a complete field reference |
| `docs/openapi.json` | The API8 spec — 145 schemas, a genuinely complete field reference. API8 isn't our target yet, but its schemas are close enough to API6's (confirmed field-by-field for the entity types below) to fill the gaps `openapi-6.json` can't |
| `docs/API-Errors.md` | the `47xx` error code table |

The captured-payload corpus is the most useful of these in practice: comparing our JSON output for an
action against the file of the same name is a two-minute check that catches field-level drift the
OpenAPI document cannot describe. Where a field-level gap below was found or refined using `openapi.json`
instead, it says so explicitly.

## Summary

| | Count |
|---|---|
| API6 canonical actions | 132 |
| Implemented here | 82 |
| Missing | 57 |
| Implemented here but not part of API6 | 7 |

(82 + 57 ≠ 132 because 7 of our actions are outside API6 — see [Actions we serve that API6 does
not](#actions-we-serve-that-api6-does-not).)

API6 additionally defines 37 `REST_ACTION` aliases (`playlists_create` → `playlist_create`, `rules` →
`search_rules`, …). Those exist only so Ampache's REST rewrite can land on the same handler; they are
irrelevant here because we expose no REST surface. They do work as `?action=` values on a real Ampache
server, so a client written against the REST paths may send them — none are currently accepted here.

We report `API6_VERSION = '6.8.0'`; the reference is at `6.9.2`.

## Missing actions

Tiering is by client demand, not by effort. Tier 1 is "a real client is broken or degraded without
it, and we already hold the data".

### Tier 1 — worth doing

| Action | Why | What we already have |
|---|---|---|
| `now_playing` | Clients show a server-wide "currently playing" view; several probe it on connect | `TrackBusinessLayer::getNowPlaying()` |
| `get_lyrics` | Lyrics display is a headline feature of the app, but is unreachable over Ampache | `DetailsService::getLyricsAsPlainText()` |
| `podcast_update` | A plain alias of `update_podcast`, which we already serve. One line | — |
| `url_to_song` | Maps a stream URL back to a song id; used when importing/queueing by URL | our own `stream` URL format |
| `song_tags` | Per-song genre list; cheap given the data | `GenreBusinessLayer` |

`catalogs` and `catalog` were in this tier and are now implemented (see
[nc-music#144](https://github.com/nc-music/music/issues/144)).

### Tier 2 — implementable, no strong client pressure

`deleted_songs`, `deleted_podcast_episodes` — incremental-sync clients use these to prune local
caches. **Needs a data-model change**: we keep no tombstones, so there is nothing to return today.

`smartlists`, `smartlist`, `smartlist_songs`, `smartlist_delete` — we serve `user_smartlists` and
`playlist_generate`, so the concept exists but the rest of the family does not.

`catalog_action` (`task=add_to_catalog` / `clean_catalog`) maps cleanly onto `Scanner` and would let a
client trigger a rescan. `catalog_file` and `catalog_folder` likewise. All three need a permission
model we do not have — Ampache gates them on `MANAGER`/`CONTENT_MANAGER`.

`update_art`, `update_from_tags`, `update_artist_info` — rescan-shaped, same permission problem.

`get_external_metadata` (we have `LastfmService`), `search_group`, `player`, `podcast_edit`,
`podcast_episode_delete`.

### Tier 3 — no meaningful Nextcloud equivalent; document as unsupported

These should keep returning `4705` rather than growing empty implementations, because an empty
success response is harder for a client to reason about than an honest "not supported":

- **Media types we do not have**: `video`, `videos`, `deleted_videos`
- **Ampache-specific playback**: `democratic`, `localplay`, `localplay_songs`
- **Ampache-specific metadata**: `license`, `licenses`, `license_songs`
- **Ampache sharing** (Nextcloud has its own, differently shaped): `share`, `shares`, `share_create`,
  `share_edit`, `share_delete`
- **Social features**: `followers`, `following`, `toggle_follow`, `friends_timeline`, `timeline`,
  `last_shouts`
- **User/system administration** (Nextcloud owns this): `users`, `user_create`, `user_edit`,
  `user_delete`, `user_update`, `register`, `lost_password`, `preference_create`, `preference_edit`,
  `preference_delete`, `system_update`
- **Destructive file operations**: `song_delete`
- **Catalog lifecycle** — meaningless for synthetic catalogs: `catalog_add`, `catalog_create`,
  `catalog_delete`

## Actions we serve that API6 does not

| Action | Status |
|---|---|
| `folders`, `folder_songs` | Deliberate proprietary extensions for folder browsing. Ampache 8 has a different `folders`; ours is not compatible with it |
| `tag`, `tags`, `tag_albums`, `tag_artists`, `tag_songs` | The pre-rename spelling of the genre actions, removed from `METHOD_LIST` after API4 (`ApiHandler::$deprecated`). **Now matched:** we answer them with the error `4706` of type `removed` on API5 and API6, adding the HTTP status 410 on API6 only, and keep serving them on API4 where they remain part of the protocol. Note the two versions genuinely differ — API5 carries the error in the body of an ordinary 200 response |

## Field-level gaps

More likely to break a client than a missing action, and much easier to miss. Compared against the
captured API6 payloads.

### `song` — vs Ampache's 46

Missing: `averagerating`, `catalog`, `channels`, `disksubtitle`, `license`.
Extra: `preciserating` (an API4-era field Ampache no longer emits).

`catalog` is the notable one now that we have catalogs — it should carry the owning catalog id, and it
is an **int** in v6 (it became a string in v8).

Ampache also flattens every `song.metadata` row into an extra top-level key (name sanitised by
replacing `` (){}/\# `` and spaces with `_`), so the v6 song object is not a closed shape.

### `album` — vs Ampache's 21

Missing: `averagerating`, `songartists`, `type` (`type` is the release type). Extra: `preciserating`.
(`mbid` and `mbid_group` are already implemented — `AmpacheController.php:2013-2014`.)

### `artist` — vs Ampache's 19

Missing: `averagerating`, `placeformed`, `summary`, `yearformed`. Extra: `preciserating`.
We hold `summary` via Last.fm already. (`mbid` is already implemented — `AmpacheController.php:1961`.)

### `playlist` — 14 vs 16

Missing: `averagerating`, `time` (summed duration of the items).

### `live_stream` — we emit two fields Ampache does not

Ampache's live_stream object is exactly six fields: `id`, `name`, `url`, `codec`, `catalog`,
`site_url`. We emit `art` and `has_art`, which do not exist there, and we omit `codec` and `catalog`.
Confirmed against a live station, which serialises as
`['art', 'has_art', 'id', 'name', 'site_url', 'url']`.

`id` is also now fixed to be a string like everywhere else (was emitted as a raw int — `RadioStation.php`).

### `podcast` — `art` points off-site

Our podcast `art` is the image URL taken verbatim from the RSS feed (e.g.
`https://fourble.co.uk/icon-regress.png`), not a URL back into the app. Ampache always serves art
through its own art endpoint. The practical consequences are that the client's IP is exposed to the
feed host, the image is unavailable when the host is, and it bypasses our caching entirely. Every
other entity type routes art through `image.php` or `get_art`.

`averagerating` is now implemented (mirrors `rating`/`preciserating`, same as every other entity type).
Still missing: `generator` (the RSS feed's `<generator>` element) — we don't parse or store it today,
so adding it needs a schema migration plus a new field on `PodcastChannelBusinessLayer::parseChannelDataFromXml`,
not just a render-side change.

### `podcast_episode` — not previously audited at the field level

Was missing, now implemented: `public_url` (mirrors `website`, same duplication `podcast` already has),
`filename` (derived from the enclosure URL's path, `PodcastEpisode::filenameFromUrl`), `mode` (hardcoded
`null`, matching how `song.mode` is also just a placeholder — cbr/vbr isn't extracted for either), `catalog`
(always the synthetic `'podcasts'` catalog id), `averagerating`.

Still missing, and not cheap: `category` (per-episode category isn't parsed from the feed — only the
channel-level one is), `rate` / `channels` (no audio metadata extraction runs on podcast enclosures, unlike
scanned audio files). `playcount` / `played` need a play-history data model we don't have for podcast
episodes. `podcast` (a back-reference to the parent channel) needs a name-resolving callback threaded
through `renderPodcastEpisodes`, the same pattern `renderAlbumOrArtistRef` already uses elsewhere.

### `genre` — missing `is_hidden` / `merge`

Not previously audited at the field level. Both are now implemented as constants (`false` / `[]`) since
this app has no genre-merge concept.

### `bookmark` — `creation_date` / `update_date` were the wrong JSON type

Not previously audited (no OpenAPI schema existed for `bookmark` until the API8 spec added one). Ampache
declares both as Unix-timestamp integers; we emitted ISO-8601 strings (`Util::formatDateTimeUtcOffset`).
Fixed to `\strtotime(...)`, matching how `Playlist::last_update` already does the same conversion.

### `handshake` / `ping`

Missing: `streamtoken`, `users`. We emit `server`, `version` and `compatible` in `handshake` as well,
where Ampache only has those in `ping`.

Note `stream token` is a distinct long-lived credential in Ampache, used as `ssid=` in every
`play_url`. We have no equivalent; our stream URLs carry the session `auth` instead, so they expire.

`max_video` was emitted as `null`, but Ampache declares it (like every other `max_*` field) as a
non-nullable integer. Fixed to `0`, matching how `videos` is already reported as `0`.

## Protocol-level gaps

**JSON list responses omit `total_count` and `md5`.** Ampache puts both on every list response:

```json
{ "total_count": 2, "md5": "89fefb…", "live_stream": [ … ] }
```

We return just `{"live_stream": [...]}`. `total_count` is the pre-limit/pre-offset count and `md5` is
`md5(serialize($ids))` over the unsliced id list — a cheap change-detection token. A client that uses
`md5` to decide whether to re-sync cannot do so against us. This is the single most impactful
protocol gap in this document.

**XML `total_count` means something different.** We emit the result count. Ampache emits
`Catalog::get_update_info(<type>)` — the server-wide total — for `album`, `artist`, `song`, `catalog`,
`live_stream`, `podcast`, `podcast_episode`, `share`, `video`, `label`, `license` and `genre`, and only
uses the result count for `browse`, `index`, `list` and `song_tags`.

**Empty results.** Ampache JSON returns `{"total_count": 0, "md5": "…", "<type>": []}`; Ampache XML
drops the type name entirely and returns a bare `<root></root>`. Ours returns `{"<type>": []}`.

**Error codes.** Ours are produced by mapping HTTP-ish codes through
`AmpacheController::mapApiV4ErrorToV5()`. Worth auditing against `ErrorCodeEnum`:

| Code | Meaning |
|---|---|
| 4700 | `ACCESS_CONTROL_NOT_ENABLED` |
| 4701 | `INVALID_HANDSHAKE` |
| 4702 | `GENERIC_ERROR` |
| 4703 | `ACCESS_DENIED` — feature disabled, e.g. `Enable: podcast` |
| 4704 | `NOT_FOUND` |
| 4705 | `MISSING` — unimplemented method |
| 4706 | `DEPRECATED` — errorType `removed` |
| 4710 | `BAD_REQUEST` |
| 4742 | `FAILED_ACCESS_CHECK` |

`errorType` is `system` for server configuration, `account` for auth/permission, and otherwise the
name of the offending parameter.

Note that API3–6 are documented as always returning HTTP 200 with the error in the body, but Ampache's
own pre-dispatch gates do set real status codes on v6 (403, 401, 410, 400). Treat the body as
canonical.

**Parameter emptiness.** `Api6::check_parameter()` treats `null`, `''` and `[]` alike as missing, so
`filter=` (empty) is a `4710` on Ampache rather than an unfiltered browse.

## Regenerating the action diff

```bash
# canonical API6 actions come from Api6.php's METHOD_LIST, resolved through each Method class's
# ACTION / REST_ACTION constants (some are inherited from an Abstract* parent)
grep -oE 'Method\\(Api6\\)?[A-Za-z0-9_]+::(ACTION|REST_ACTION)' \
    ../ampache-develop8/src/Module/Api/Api6.php | sort -u

# ours are simply the attributed methods
grep -B1 'function ' lib/Controller/AmpacheController.php | grep -A1 'AmpacheAPI'
```
