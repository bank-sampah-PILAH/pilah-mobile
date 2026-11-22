/// Icons in `lib/` whose glyph is not a literal `Icons.x`, counted per file
/// (path below `lib/`).
///
/// The screen recording shows every icon (see `replayTextMask`), so an icon
/// chosen from what a person or a bank sampah *is* (a gender, an approval
/// status) would be readable in it. Such an icon must be wrapped in
/// `HideInReplay`. The icons below were looked at when this list was made and
/// are decided by the UI (expanded or not, sorted up or down), by the catalog
/// (a jenis sampah), by a fixed destination, or passed in by a caller.
///
/// The list is a ratchet: a new non-literal icon fails the test until it is
/// either wrapped in `HideInReplay` or added here, and a file that lost one
/// must lower its number. Do not raise a number to make the test pass without
/// reading where the icon comes from.
const replayIconBaseline = <String, int>{};
