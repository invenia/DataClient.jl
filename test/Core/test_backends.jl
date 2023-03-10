using DataClient: Configs, FFS, S3DB, Store
using DataStructures

@testset "test src/backends.jl" begin
    Configs.reload_configs(joinpath(pwd(), "configs.yaml"))  # reset to default path
    cfg_prefix = abspath(joinpath(@__DIR__, "..", "files", "configs"))

    @testset "test configs - missing config file" begin
        # We've not added a config file to the default config path in tests, so only
        # hard-coded centralized stores will be available.
        @test "datafeeds" in keys(get_backend())
        @test get_backend("datafeeds") ==
            S3DB("invenia-datafeeds-output", "version5/aurora/gz/")
    end

    @testset "test configs - valid config file" begin
        reload_backend(joinpath(cfg_prefix, "configs_valid.yaml"))

        @test "myffs" in keys(get_backend())
        @test get_backend("myffs") == FFS("my-bucket", "my-prefix/")
    end

    @testset "test configs - disable centralized stores" begin
        reload_backend(joinpath(cfg_prefix, "configs_disable_centralized.yaml"))

        @test get_backend() == OrderedDict{String,DataClient.Store}(
            "miso-nda" => FFS("miso-nda", "miso-prefix/"),
            "myffs" => FFS("my-bucket", "my-prefix/"),
        )
    end

    @testset "test configs - prioritize additional stores" begin
        reload_backend(joinpath(cfg_prefix, "configs_prioritize_additional.yaml"))

        @test collect(get_backend())[1][1] == "myffs"
    end

    @testset "test configs - invalid configs" begin
        @test_throws ConfigFileError(
            "Do not set `disable-centralized: True` in the config file when no " *
            "`additional-stores` are defined.",
        ) reload_backend(joinpath(cfg_prefix, "configs_invalid.yaml"))
    end

    @testset "test configs - invalid store id" begin
        Configs.reload_configs(joinpath(pwd(), "configs.yaml"))  # reset to default path
        store_id = "new-store"
        @test_throws ConfigFileError(
            "Store id/uri '$store_id' is not registered or is invalid."
        ) get_backend(store_id)
    end

    @testset "test configs - invalid store uri" begin
        @test_throws ConfigFileError(
            "Unknown backend type 'ffs2' for 'ffs2:s3://my-bucket/my-prefix/'"
        ) reload_backend(joinpath(cfg_prefix, "configs_invalid_uri.yaml"))

        @test_throws ConfigFileError("Invalid uri scheme 's4://my-bucket/my-prefix/'") reload_backend(
            joinpath(cfg_prefix, "configs_invalid_uri_2.yaml")
        )
    end
end
