# Cookie Parser based on MDN's DocCookie function
# https://developer.mozilla.org/en-US/docs/DOM/document.cookie

# cookie = new Cookie("token=abcde")
# cookie.getItem("token") ==> "abcde"
# cookie.hasItem("token") ==> "true"
# cookie.keys()           ==> ["token"]

class Cookie

  constructor: (cookie) ->
    @cookie = cookie

  getItem: (sKey) ->
    return null  if not sKey or not @hasItem(sKey)
    unescape @cookie.replace(new RegExp("(?:^|.*;\\s*)" + escape(sKey).replace(/[\-\.\+\*]/g, "\\$&") + "\\s*\\=\\s*((?:[^;](?!;))*[^;]?).*"), "$1")

  hasItem: (sKey) ->
    (new RegExp("(?:^|;\\s*)" + escape(sKey).replace(/[\-\.\+\*]/g, "\\$&") + "\\s*\\=")).test @cookie

  keys: -> # optional method: you can safely remove it!
    aKeys = @cookie.replace(/((?:^|\s*;)[^\=]+)(?=;|$)|^\s*|\s*(?:\=[^;]*)?(?:\1|$)/g, "").split(/\s*(?:\=[^;]*)?;\s*/)
    nIdx = 0

    while nIdx < aKeys.length
      aKeys[nIdx] = unescape(aKeys[nIdx])
      nIdx++
    aKeys

module.exports = Cookie
