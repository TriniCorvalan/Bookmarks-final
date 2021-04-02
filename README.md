# Desafío Marcadores

### 1. Modelos

![Diagrama de relaciones](erd.pdf)

Este proyecto tiene 3 modelos principales:

| Modelo   | Atributos     |
| -------- | ------------- |
| Category | - title - is_public - category_id (_hace referencia al mismo modelo como categoría padre_) |
| Kind     | - title       |
| Bookmark | - title  -url |


Además tiene dos modelos intermedios

| Modelo           | Atributos     |
| ---------------- | ------------- |
| BookmarkCategory | - bookmark_id  - category_id |
| BookmarkKind     | - bookmark_id - kind_id     |

### 2. CRUD

#### CRUD Tipos

El CRUD para administrar los tipos se hace con un scaffold `rails g scaffold Kind title`. 

Además se debe agregar la relación con los marcadores a través de la table intermedia y esto se puede hacer con `has_many through` como lo siguiente:

```ruby
 class Kind < ApplicationRecord
    has_many :bookmarks, through: :bookmark_kinds
    has_many :bookmark_kinds
  end
```

Dentro del modelo podemos agregar la validación de unicidad de nombre y el método `to_s` para que muestre el titulo al llamar al objeto. Quedando así:

```ruby
  class Kind < ApplicationRecord
    has_many :bookmarks, through: :bookmark_kinds
    has_many :bookmark_kinds

    validates :title, uniqueness: true

    def to_s
      title
    end
  end
```

#### CRUD Categorías

El CRUD para administrar las categorías también ocupa un scaffold `rails g scaffold Category title is_public category:references`. Pero para poder generar bien la relación se debe editar el modelo de tal forma que category_id sea opcional. En este caso también podemos generar el tipo de relación a través de parent_category y children_categories agregando lo siguiente:

```ruby
  class Category < ApplicationRecord
    belongs_to :parent_category, class_name: "Category", optional: true, foreign_key: 'category_id'
    has_many :children_categories, class_name: "Category", foreign_key: "category_id"
  end
```

Además se debe agregar la relación con los marcadores a través de la table intermedia y esto se puede hacer con `has_many through` como lo siguiente:

```ruby
  class Category < ApplicationRecord
    belongs_to :parent_category, class_name: "Category", optional: true, foreign_key: 'category_id'
    has_many :children_categories, class_name: "Category", foreign_key: "category_id"

    has_many :bookmark_categories
    has_many :bookmarks, through: :bookmark_categories
  end
```

Se puede agregar en el mismo modelo las validaciones necesarias y el método `to_s` para que muestre el titulo al llamar al objeto. Finalmente queda así.

```ruby
  class Category < ApplicationRecord
    belongs_to :parent_category, class_name: "Category", optional: true, foreign_key: 'category_id'
    has_many :children_categories, class_name: "Category", foreign_key: "category_id"
    
    has_many :bookmark_categories
    has_many :bookmarks, through: :bookmark_categories
    

    validates :title, presence: true

    def to_s
      title
    end
  end
```

Para que el CRUD funcione correctamente dadas estas relaciones, debemos modificar en las vistas la referencia a category.

En index y show se cambia: 

```ruby
<td><%= category.category %></td>
```
por
```ruby
<td><%= category.parent_category %></td>
```

y en form se cambia el input de category por:

```ruby
  <div class="field">
    <%= form.label :category_id %>
    <%= form.collection_select :category_id, Category.all, :id, :title, prompt: "Selecciona una categoría si quieres" %>
  </div>
```

#### CRUD Marcadores

Para los marcadores no ocuparemos scaffold, se generará primero el modelo `rails g model Bookmark title url`, revisar y correr la migración. Generamos las relaciones intermedias en el modelo:

```ruby
  class Bookmark < ApplicationRecord
    has_many :bookmark_categories
    has_many :categories, through: :bookmark_categories
    
    has_many :bookmark_kinds
    has_many :kinds, through: :bookmark_kinds
    
  end
```

Luego el controllador con los 7 métodos `rails g controller Bookmarks index show new edit create update destroy`. En el archivo de `routes.rb` cambiamos las nuevas rutas por `resources :bookmarks`. En el controlador generamos los métodos privados de `set_bookmark` y `bookmarks_params` como se muestra para que pueda tomar multiples categorías y tipos.

```ruby
  private
    # Use callbacks to share common setup or constraints between actions.
    def set_bookmark
      @bookmark = Bookmark.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def bookmarks_params
      params.require(:bookmark).permit(:title, :url, category_ids: [], kind_ids: [])
    end
```

Agregamos un callback para este método con: 

```ruby
  before_action :set_bookmark, only: %i[ show edit update destroy ]
```
al comienzo del controlador.

Y definimos los otros métodos y vistas similares a como los define un scaffold.


### 3. Formulario remoto para marcadores

Se hace un render del parcial `form` en la vista `index` y se le pasan las variables necesarias con 
```ruby
<%= render "form", bookmark: @bookmark %>
```
En la vista parcial `form` se cambia `local: true` por `remote: true` y se agrega un mensaje de confirmación en el submit con `data: { confirm: 'Seguroski?' }`.
En el método index del controlador definimos `@bookmark = Bookmark.new` para que pueda ser recibido por el form.
En el método create del controlador definimos la respuesta `.js` con `format.js {}`.
Se crea la vista `create.js.erb` que agregará el marcador creado a la lista del index. Esta vista contiene lo siguiente:
```javascript
  $("#bookmarks-list").append("<%= escape_javascript(render partial: 'bookmark', locals: {b: @bookmark}) %>");
```

(_para usar esta sintaxis es necesario agregar jquery ya sea como gema o con yarn_)
Necesitaremos esa vista parcial bookmark que contiene el marcador nuevo con el mismo formato que se tiene en el index:

```ruby
<tr>
  <td><%= b.title %></td>
  <td><%= b.url %></td>
  <td>
    <% b.categories.each do |c| %>
      <%= c %> <br>
    <% end %>
  </td>
  <td>
    <% b.kinds.each do |k| %>
      <%= k %> <br>
    <% end %>
  </td>
  <td><%= link_to 'Show', bookmark_path(b) %></td>
  <td><%= link_to 'Edit', edit_bookmark_path(b) %></td>
  <td><%= link_to 'Destroy', bookmark_path(b), method: :delete, data: { confirm: 'Are you sure?' } %></td>
</tr>
```

### 4. Respuesta JSON para categoría

Podemos generar un nuevo método en el controlador de categorías que llamaremos `api` (por su similitud en la respuesta).
En este método definiremos la categoría a buscar y el hash con la información de esta categoría para luego hacer un render de este en formato json, de la siguiente forma:

```ruby
  def api
    category = Category.find(params[:id])
    hash = {
      title: category.title,
      is_public: category.is_public,
      parent_category: category.parent_category,
      children_categories: category.children_categories,
      bookmarks: category.bookmarks.pluck(:title)
    }
    render json: hash
  end
```

Se debe crear la ruta, en este caso de tipo get que recibirá el id de la categoría que se busca. Queda así:
```ruby
get "categories/:id/api", to: "categories#api", as: "api"
```

Teniendo esto se puede implementar un link en el show o index de la categoría para pedir el json. Esto lo agregamos con:

```ruby
<%= link_to 'API', api_path(@category) %>
```

### 5. Registros predefinidos

Para generar una serie de registros en la base de datos podemos crear un seed, en este archivo ocuparemos la gema [Faker](https://github.com/faker-ruby/faker) (_en la documentación están los pasos para su instalación_). Se podrían generar distintos seeds para cada modelo, pero dado que no son tantos, lo haremos en uno. Quedaría de la siguiente forma:
(_para mantener la unicidad en los títulos se agrega un numero correspondiente al índice_)
```ruby
require 'faker'

20.times do |i|
  title = Faker::Commerce.department + (i + 1).to_s
  Kind.create!(title: title)
end

5.times do |i|
  title = Faker::Hipster.word + (i + 1).to_s
  is_public = [true, false].sample
  Seed = Category.create!(title: title, is_public: is_public)
  10.times do |j|
    title = Faker::Hipster.word + (j + 1).to_s
    is_public = [true, false].sample
    category_id = Seed.id
    Category.create!(title: title, is_public: is_public, category_id: category_id)
  end
end

categories = Category.all
kinds = Kind.all

10.times do |i|
  title = Faker::Hipster.word + (i + 1).to_s
  url = Faker::Internet.url
  Bookmark.create!(title: title, url: url)
end

Bookmark.all.each do |b|
  3.times do 
    BookmarkCategory.create!(bookmark: b, category: categories.sample)
    BookmarkKind.create!(bookmark: b, kind: kinds.sample)
  end
end
```

### Gráfico de marcadores

Para generar un gráfico necesitaremos de la gema [Chartkick](https://chartkick.com/) (_en la documentación están los pasos para su instalación_). 

Podemos crear un controlador Home con un método index para que contenga el gráfico. En este método definiremos los marcadores y los agruparemos por tipos según nombre.

```ruby
  @bookmarks = Bookmark.joins(:kinds).group("kinds.title").count
```

Luego en la vista index se agrega el gráfico de torta con:

```ruby
<%= pie_chart @bookmarks %>
```
