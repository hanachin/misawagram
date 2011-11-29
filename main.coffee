$ ->
  $(".container a.tile").lightBox()
  $(".tile").tipsy( gravity: 'n', fade: true )
  $("#categories").bind 'change', ->
    if $(this).val() is "all"
      $(".tile").each -> $(this).css("display", "inline")
      return
    cat = "cat#{$(this).val()}"
    $(".tile").each ->
      if $(this).hasClass(cat)
        $(this).css("display", "inline")
      else
        $(this).css("display", "none")
    $(".tile:visible").lightBox()
    $("body").trigger("scroll")
  $(".lazy").lazyload({ threshold: 400 })
