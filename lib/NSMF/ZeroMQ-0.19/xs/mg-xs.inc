STATIC_INLINE
int
PerlZMQ_mg_free(pTHX_ SV * const sv, MAGIC *const mg ) {
    PERL_UNUSED_VAR(sv);
    Safefree(mg->mg_ptr);
    return 0;
}

STATIC_INLINE
int
PerlZMQ_mg_dup(pTHX_ MAGIC* const mg, CLONE_PARAMS* const param) {
    PERL_UNUSED_VAR(mg);
    PERL_UNUSED_VAR(param);
    return 0;
}

static MGVTBL PerlZMQ_Raw_Context_vtbl = { /* for identity */
    NULL, /* get */
    NULL, /* set */
    NULL, /* len */
    NULL, /* clear */
    PerlZMQ_Raw_Context_mg_free, /* free */
    NULL, /* copy */
    PerlZMQ_Raw_Context_mg_dup, /* dup */
#ifdef MGf_LOCAL
    NULL  /* local */
#endif
};

static MGVTBL PerlZMQ_Raw_Socket_vtbl = { /* for identity */
    NULL, /* get */
    NULL, /* set */
    NULL, /* len */
    NULL, /* clear */
    PerlZMQ_Raw_Socket_mg_free, /* free */
    NULL, /* copy */
    PerlZMQ_Raw_Socket_mg_dup, /* dup */
#ifdef MGf_LOCAL
    NULL  /* local */
#endif
};

static MGVTBL PerlZMQ_Raw_Message_vtbl = { /* for identity */
    NULL, /* get */
    NULL, /* set */
    NULL, /* len */
    NULL, /* clear */
    PerlZMQ_Raw_Message_mg_free, /* free */
    NULL, /* copy */
    PerlZMQ_Raw_Message_mg_dup, /* dup */
#ifdef MGf_LOCAL
    NULL  /* local */
#endif
};

static MGVTBL PerlZMQ_Raw_PollItem_vtbl = { /* for identity */
    NULL, /* get */
    NULL, /* set */
    NULL, /* len */
    NULL, /* clear */
    PerlZMQ_mg_free, /* free */
    NULL, /* copy */
    PerlZMQ_mg_dup, /* dup */
#ifdef MGf_LOCAL
    NULL  /* local */
#endif
};

