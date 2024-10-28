import std.format : format;
import std.string : toStringz;
import unit_integration;

int main(string[] args)
{
    nxt_unit_init_t init;
    init.callbacks.request_handler = &(unitRequestHandler);
    init.callbacks.ready_handler = &(unitReadyHandler);
    nxt_unit_ctx_t* unitContext = nxt_unit_init(&init);
    if (unitContext is null)
    {
        logUnit(
            null,
            UnitLogLevel.alert,
            "Failed to initialize NGINX Unit context"
        );
        return NXT_UNIT_ERROR;
    }

    auto rc = nxt_unit_run(unitContext);
    nxt_unit_done(unitContext);
    return rc;
}

extern(C)
void unitRequestHandler(nxt_unit_request_info_t* requestInfo)
{
    ushort statusCode = 200;
    auto response = "Hello, World!\n";
    auto contentType = ["Content-Type", "text/plain"];

    auto rc = nxt_unit_response_init(
        requestInfo,
        statusCode,
        cast(uint)1,
        cast(uint)(
            contentType[0].length +
            contentType[1].length +
            response.length
        )
    );
    if (rc != NXT_UNIT_OK)
        goto fail;

    rc = nxt_unit_response_add_field(
        requestInfo,
        contentType[0].toStringz,
        cast(ubyte)contentType[0].length,
        contentType[1].toStringz,
        cast(uint)contentType[1].length
    );
    if (rc != NXT_UNIT_OK)
        goto fail;

    rc = nxt_unit_response_add_content(
        requestInfo,
        response.toStringz,
        cast(uint)response.length
    );
    if (rc != NXT_UNIT_OK)
        goto fail;

    rc = nxt_unit_response_send(requestInfo);
    if (rc != NXT_UNIT_OK)
        goto fail;

    fail:
    nxt_unit_request_done(requestInfo, rc);
}

extern(C)
int unitReadyHandler(nxt_unit_ctx_t* context)
{
    return NXT_UNIT_OK;
}

void logUnit(
    nxt_unit_ctx_t* unitContext,
    UnitLogLevel logLevel,
    string message
)
{
    nxt_unit_log(unitContext, logLevel, ("[D] " ~ message).toStringz);
}

enum UnitLogLevel : uint
{
    alert = NXT_UNIT_LOG_ALERT,
    error = NXT_UNIT_LOG_ERR,
    warn = NXT_UNIT_LOG_WARN,
    notice = NXT_UNIT_LOG_NOTICE,
    info = NXT_UNIT_LOG_INFO,
    debug_ = NXT_UNIT_LOG_DEBUG,
};
