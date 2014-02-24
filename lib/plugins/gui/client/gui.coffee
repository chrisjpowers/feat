$ ->
  updateDisplay = (data) ->
    ul = $("#features")
    ul.empty()
    for name, val of data
      displayedVal = if val then "on" else "off"
      li = $("<li>", html: "#{name}: <span class='on'>#{displayedVal}</span> <a href='#' class='toggle'>Toggle</a>")
      li.data "feature-name", name
      li.data "feature-enabled", val
      ul.append li

  $("#container").delegate ".toggle", "click", (e) ->
    e.preventDefault()
    li = $(this).parent()
    name = li.data "feature-name"
    newVal = !li.data("feature-enabled")
    payload = {}
    payload[name] = newVal
    $.post "features.json", payload, updateDisplay

  $.getJSON "features.json", updateDisplay

