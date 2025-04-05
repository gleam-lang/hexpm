import gleam/dict.{type Dict}
import gleam/dynamic/decode as de
import gleam/option.{type Option, None}
import gleam/time/timestamp.{type Timestamp}

/// Information on a package from Hex's `/api/packages` endpoint.
pub type Package {
  Package(
    name: String,
    html_url: Option(String),
    docs_html_url: Option(String),
    meta: PackageMeta,
    downloads: Dict(String, Int),
    owners: Option(List(PackageOwner)),
    releases: List(PackageRelease),
    inserted_at: Timestamp,
    updated_at: Timestamp,
  )
}

pub type PackageMeta {
  PackageMeta(
    links: Dict(String, String),
    licenses: List(String),
    description: Option(String),
  )
}

pub type PackageRelease {
  PackageRelease(version: String, url: String, inserted_at: Timestamp)
}

pub type PackageOwner {
  PackageOwner(username: String, email: Option(String), url: String)
}

pub fn package_decoder() -> de.Decoder(Package) {
  use name <- de.field("name", de.string)
  use html_url <- de.field("html_url", de.optional(de.string))
  use docs_html_url <- de.field("docs_html_url", de.optional(de.string))
  use meta <- de.field("meta", {
    use links <- de.field("links", de.dict(de.string, de.string))
    use licenses <- de.field("licenses", de.list(de.string))
    use description <- de.field("description", de.optional(de.string))
    de.success(PackageMeta(links:, licenses:, description:))
  })
  use downloads <- de.field("downloads", de.dict(de.string, de.int))
  use owners <- de.optional_field(
    "owners",
    None,
    de.optional(de.list(package_owner_decoder())),
  )
  use releases <- de.field(
    "releases",
    de.list({
      use version <- de.field("version", de.string)
      use url <- de.field("url", de.string)
      use inserted_at <- de.field("inserted_at", timestamp_decoder())
      de.success(PackageRelease(version:, url:, inserted_at:))
    }),
  )
  use inserted_at <- de.field("inserted_at", timestamp_decoder())
  use updated_at <- de.field("updated_at", timestamp_decoder())
  de.success(Package(
    name:,
    html_url:,
    docs_html_url:,
    meta:,
    downloads:,
    owners:,
    releases:,
    inserted_at:,
    updated_at:,
  ))
}

fn timestamp_decoder() -> de.Decoder(Timestamp) {
  use string <- de.then(de.string)
  case timestamp.parse_rfc3339(string) {
    Ok(timestamp) -> de.success(timestamp)
    Error(_) -> de.failure(timestamp.from_unix_seconds(0), "Timestamp")
  }
}

/// Information on a release from Hex's `/api/packages/:name/releases/:version`
/// endpoint.
pub type Release {
  Release(
    version: String,
    url: String,
    checksum: String,
    downloads: Int,
    publisher: Option(PackageOwner),
    meta: ReleaseMeta,
    retirement: Option(ReleaseRetirement),
    inserted_at: Timestamp,
    updated_at: Timestamp,
  )
}

/// Meta for a hex release
pub type ReleaseMeta {
  ReleaseMeta(app: Option(String), build_tools: List(String))
}

pub type ReleaseRetirement {
  ReleaseRetirement(reason: RetirementReason, message: Option(String))
}

pub type RetirementReason {
  OtherReason
  Invalid
  Security
  Deprecated
  Renamed
}

pub fn retirement_reason_decoder() -> de.Decoder(RetirementReason) {
  use string <- de.then(de.string)
  case string {
    "invalid" -> de.success(Invalid)
    "security" -> de.success(Security)
    "deprecated" -> de.success(Deprecated)
    "renamed" -> de.success(Renamed)
    _ -> de.success(OtherReason)
  }
}

pub fn retirement_reason_to_string(reason: RetirementReason) -> String {
  case reason {
    OtherReason -> "other"
    Invalid -> "invalid"
    Security -> "security"
    Deprecated -> "deprecated"
    Renamed -> "renamed"
  }
}

pub fn release_decoder() -> de.Decoder(Release) {
  use version <- de.field("version", de.string)
  use url <- de.field("url", de.string)
  use checksum <- de.field("checksum", de.string)
  // For some unknown reason Hex will return [] when there are no downloads.
  use downloads <- de.field("downloads", de.one_of(de.int, [de.success(0)]))
  use publisher <- de.field("publisher", de.optional(package_owner_decoder()))
  use meta <- de.field("meta", {
    use app <- de.optional_field("app", None, de.optional(de.string))
    use build_tools <- de.field("build_tools", de.list(de.string))
    de.success(ReleaseMeta(app:, build_tools:))
  })
  use retirement <- de.optional_field(
    "retirement",
    None,
    de.optional({
      use reason <- de.field("reason", retirement_reason_decoder())
      use message <- de.field("message", de.optional(de.string))
      de.success(ReleaseRetirement(reason:, message:))
    }),
  )

  use inserted_at <- de.field("inserted_at", timestamp_decoder())
  use updated_at <- de.field("updated_at", timestamp_decoder())
  de.success(Release(
    version:,
    url:,
    checksum:,
    downloads:,
    publisher:,
    meta:,
    retirement:,
    inserted_at:,
    updated_at:,
  ))
}

fn package_owner_decoder() -> de.Decoder(PackageOwner) {
  use username <- de.field("username", de.string)
  use email <- de.optional_field("email", None, de.optional(de.string))
  use url <- de.field("url", de.string)
  de.success(PackageOwner(username:, email:, url:))
}
