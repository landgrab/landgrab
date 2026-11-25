# Spec: Post associations on the post form, and "Create a post about…" links

## Problem Statement

An admin writing a **Post** has to save it first and only then, on the edit page, attach it to the teams, projects, plots and tiles (its **postables**) that should see it. Until they do, nobody can view the post. The new-post and edit-post screens also behave differently: new has no association controls at all, while edit has four separate add forms plus per-association "Unassociate" buttons. When an admin is already looking at a team, project, plot or tile and wants to write about it, there is no shortcut: they must open a blank new-post form and associate it afterwards.

## Solution

The post form (new and edit) gets one shared "Associations" section with a field for each type of postable: teams, projects, plots and tiles. Admins choose the **post associations** while creating the post, and the same fields, pre-filled with the current associations, are used when editing. Saving makes the post's associations match what was chosen.

Next to each team, project, plot and tile in the admin area (index rows and show pages) there is a "Create a post about this …" link. It opens the new-post form with that postable already selected, still editable.

## User Stories

1. As an admin, I want to choose teams, projects, plots and tiles on the new-post form, so that the post is visible to the right people as soon as it is created.
2. As an admin, I want to save a post with no associations, so that I can keep a draft nobody can see yet.
3. As an admin, I want to pick several teams at once, so that one post can reach more than one team.
4. As an admin, I want to pick several projects at once, so that one post can reach more than one project.
5. As an admin, I want to pick several plots at once, grouped by their project, so that I can find the right plots quickly.
6. As an admin, I want to type a comma-separated list of What3Words addresses for tiles, so that I can attach a post to specific tiles.
7. As an admin, I want the tiles field to accept addresses with spaces around the commas or with a leading `///`, so that pasting addresses from elsewhere just works.
8. As an admin, I want a hint on the new-post form that I can choose tiles from a map after creating the post, so that I know a map picker exists.
9. As an admin, I want a "choose tiles from a map" link on the edit form, so that I can bulk-associate the tiles of a plot visually.
10. As an admin, I want tiles mentioned as `///a.b.c` in the post body to still be associated automatically, so that existing behaviour keeps working.
11. As an admin, I want the edit form to show the current associations pre-selected in the same fields, so that new and edit feel the same.
12. As an admin, I want saving an edit to add and remove associations to match my selection, so that I can fix mistakes without separate remove buttons.
13. As an admin, I want unselecting every team (or project, plot, tile) to remove all associations of that type, so that I can clear them.
14. As an admin, I want associations of a type I did not touch to be left alone, so that a partial update never wipes them.
15. As an admin, I want my selections kept when the form re-renders after a validation error, so that I don't have to choose them again.
16. As an admin, I want a "Create a post about this team" link on each team's index row and show page, so that I can write about a team in one click.
17. As an admin, I want the same "Create a post about this project" link on project index rows and show pages.
18. As an admin, I want the same "Create a post about this plot" link on plot index rows and show pages.
19. As an admin, I want the same "Create a post about this tile" link on tile index rows and the tile show page.
20. As an admin, I want the new-post form opened from such a link to have that postable pre-selected, so that I don't have to find it again.
21. As an admin, I want to change or add to the pre-selected postable before saving, so that the link is a starting point, not a restriction.
22. As an admin, I want a link with an unknown or tampered postable type or ID to just open an ordinary blank form, so that a bad link never breaks the page.
23. As an admin, I want the form text to say the post is visible only to users connected to the chosen postables, so that I understand what the associations do.
24. As a subscriber, I want to see posts as soon as an admin publishes them for my tile, plot, project or team, so that I'm not waiting on a second manual step.

## Implementation Decisions

- The post form is shared by new and edit and includes a single associations section; the four separate add-association forms on the edit page are removed, along with their partials.
- The post form submits association choices as part of the post: a list of teams, a list of projects, a list of plots (all by their public hashid identifiers) and one text value holding the comma-separated tile What3Words addresses.
- A single sync operation makes a post's associations match a given selection, type by type. A type whose selection is not submitted is left untouched; a type submitted empty is cleared. Unknown identifiers or addresses are silently skipped for now.
- Create saves the post, then syncs the chosen associations, then associates any tiles mentioned in the body, then applies "publish immediately". Update syncs the submitted associations, then associates tiles newly mentioned in the body.
- Associations are optional. The old note saying the post is invisible until associated manually is replaced by text explaining that it is visible only to users connected to the chosen postables.
- The new-post form accepts a postable type (team, project, plot or tile) and its identifier as query parameters and pre-selects that single postable. Unrecognised types or identifiers are ignored. The preset is shown pre-filled and remains editable.
- What the fields show is decided in this order: submitted values after a failed save, else the post's current associations, else the preset from the query parameters, else empty.
- Tile addresses on edit are listed in full in the tiles field, including tiles added through the map picker. This keeps new and edit consistent but the field can become long for posts attached to many tiles.
- Each of the four admin postable types gets a "Create a post about this team/project/plot/tile" link, shown on its index rows and its show page (on the tile page, within the posts section).
- The glossary gains the term **Post association**: the link attaching a post to one postable (avoid "tag", "target", "link"). Existing **Postable** is unchanged.
- The map-based bulk association page and its routes are unchanged.
- The standalone create/destroy actions for post associations and their routes are no longer used by any form. Whether to remove them is an open decision for the project owner, since project guidance requires asking before keeping or dropping code for backwards compatibility.

## Testing Decisions

- A good test exercises external behaviour: the associations that exist after a request, and what the rendered page offers. It does not test the sync operation or helper methods directly.
- Main seam: the admin posts controller specs.
  - Create: chosen teams, projects, plots and tiles are associated; a post with no associations still saves; tile mentions in the body are still associated.
  - Update: submitted types are replaced; an emptied type is cleared; unsubmitted types are preserved; mention behaviour is unchanged.
  - New with rendered views: a preset team, project, plot or tile arrives pre-selected or pre-filled; an unknown type renders a normal blank form.
- Links seam: the existing admin show-page controller specs, with rendered views, asserting the "Create a post about this …" link targets the new-post form with the right type and identifier. Index row links are not tested separately.
- The sync operation is covered through the controller specs only, so any dedicated service spec should be removed.
- Prior art: the existing admin posts create and update controller specs, which already use signed-in admin users and factories for posts, tiles, teams, projects and plots.

## Out of Scope

- Picking tiles from a map on the new-post screen (recorded in the TODO list).
- Validating unknown What3Words addresses in the tiles field and showing an error that names them (recorded in the TODO list).
- Changes to the public (non-admin) post pages or how viewability is calculated.
- Changes to the map-based bulk association page.
- Removing the now-unused standalone post association create/destroy actions and routes, pending a decision.

## Further Notes

- Implemented on branch `post-associations-on-post-form`; the full suite and rubocop pass. It has not yet been checked in a browser.
- The tiles field uses a text area so long lists remain editable; a future improvement is the map picker on the new screen.
