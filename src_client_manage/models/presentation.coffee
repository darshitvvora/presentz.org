###
Presentz.org - A website to publish presentations with video and slides synchronized.

Copyright (C) 2012 Federico Fissore

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
###

"use strict"

class Presentation extends Backbone.DeepModel

  urlRoot: "/m/api/presentations/"

  validate: @validation

  loaded: false
  slides_to_delete: []

  initialize: () ->
    _.bindAll(@)

    @bind "change", () ->
      @loaded = true
      for chapter, chapter_idx in @get("chapters")
        chapter._index ?= chapter_idx
        for slide, slide_idx in chapter.slides
          slide._index ?= slide_idx
          slide._onebased_index ?= slide_idx + 1
      return

    keys = (key for key, value of @attributes)

    if keys.length > 1
      @set "id", utils.generate_id(window.accent.accent_fold, @get("title"))
      @trigger("change", @, {})
    
    return

  toJSON: () ->
    presentation = $.extend true, {}, @attributes

    utils.visit_presentation presentation, utils.remove_unwanted_fields_from, [ "onebased", "$idx", "$len", "_plugin" ]

  delete_slides = (slides, callback) ->
    return callback() if !slides? or slides.length is 0

    slide = slides.pop()

    delete_slides(slides, callback) unless slide["@rid"]?

    $.ajax
      type: "DELETE"
      url: "/m/api/delete_slide/#{slide["@rid"].substr(1)}"
      success: () ->
        delete_slides(slides, callback)
      error: () ->
        views.alert("An error occured while deleting the slides")
    
    return

  save: (attributes, options) ->
    options ||= {}
    options.success = (model, resp) =>
      if @slides_to_delete.length is 0
        return @trigger("sync", model, resp)

      delete_slides @slides_to_delete, () =>
        @loaded = false
        @fetch { success: () => @trigger("sync") }

    Backbone.DeepModel.prototype.save.call(this, attributes, options)

@models.Presentation = Presentation