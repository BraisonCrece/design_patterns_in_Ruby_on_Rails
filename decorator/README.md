# Decorator

En este repositorio podemos ver un ejemplo de utilidad 
del patrón de diseño **decorator**. Y de como poder utilizarlo para organizar nuestras vistas, y eliminar lógica de su interior. Y todo esto sin utilizar helpers.

## ¿Qué es un decorator?

Un decorator es una clase que contiene la lógica de presentación de un modelo para que no se mezcle con la lógica de negocio.

Imaginémonos el supuesto en el que tengamos que mostrar datos
de un modelo usuario:

```rb
  create_table "users", force: :cascade do |t|
    t.string   "first_name"
    t.string   "last_name"
    t.integer  "months_subscribed"
    t.boolean  "moderator"
    t.boolean  "admin"
    t.datetime "created_at",        null: false
    t.datetime "updated_at",        null: false
  end
```

Queremos mostrar su nombre completo, que en este caso está compuesto, por su nombre `first_name` y su apellido `last_name`.

En primera instancia, lo que se nos viene a la mente es hacer lo siguiente:

```erb
<h1>Users</h1>
<% @users.each do |user| %>
  <div>
    <%= user.first_name%>
    <%= user.last_name.first%>
  </div>
<% end %>
```

```
USERS

Edie M.
Coleman M.
Tyrone R.
Darius S.
Dominique V.
Mindy M.
Enrique M.
Rosia M.
Arlie H.
Maria C.
```

Al estar mostrando solo la primera letra del apellido utlizando el método `first`, estaremos obteniendo los datos de usuario y actuando sobre ellos en todo momento que queramos que sean mostrados. Esto no es lo que queremos.

La primera opción que se nos puede venir a la mente es definir un método en el modelo `user` tal que así:

```rb 
class User < ApplicationRecord
  def name
    "#{first_name} #{last_name.first}."
  end
end
```

Y llamar al método en las vistas:

```erb
<h1>Users</h1>
<% @users.each do |user| %>
  <div>
    <%= user.name %>
  </div>
<% end %>
```

Con esto lo que conseguimos es tener centralizado la definición del nombre formateado, y podemos ultilizarlo donde queramos.

Esto es una buena mejora, porque aparte de poder llamar el método de instancia donde queramos, el día que queramos modificar su comportamiento, solamente tendremos que ir al modelo y modificar el código del método, en lugar de tener que modificar la lógica en las vistas.

A pesar de esto, añadir este tipo de lógica a los modelos no es lo mejor, puesto que es mejor tener un modelo legible y lo más minimalista posible. 

Lo siguiente que se nos viene a la mente es utilizar un `view helper` 

```rb
module UsersHelper
  def name(user)
    "#{user.first_name} #{user.last_name.first}."
  end
end
```

```erb
<h1>Users</h1>
<% @users.each do |user| %>
  <div>
    <%= name(user) %>
  </div>
<% end %>
```

Pues bien, esto parece estar más que correcto, pues estamos moviendo lógica de la vistas hacia un lugar centralizado donde podremos acceder en el futuro si necesitamos cambiar algo.

Y esto es cierto, excepto cuando tenemos aplicaciones muy grandes y el nombre de nuestro helper puede confundirse con otros, por ejemplo imaginemos que tenemos un modelo del cual queremos extraer también el nombre:

```rb
module EpisodesHelper
  def name(episode)
    "#{episode.number} #{episode.title}."
  end
end
```

Esto es un problema...

Y podríamos pensar que una solución sería la siguiente:

```rb
  def user_name(user)
    "#{user.first_name} #{user.last_name.first}."
  end
  
  def episode_name(episode)
    "#{episode.number} #{episode.title}."
  end
```

Esto nunca debe de ser una opción para nosotros si lo que queremos es construir aplicaciones escalables y organizadas, siguiendo buenas prácticas de diseño y codificación, pues no queremos tener dos métodos que son globalmente accesibles dentro de nuestra aplicación con una nomenclatura tan pobre. Especialmente con `user_name()`, es el `username` (nick)? o quizás el `user's name` (nombre del usuario)?.

## Vamos a solucionar este problema creando un `decorator`

No existe nada demasiado especial en los `decorators`, simplemente son como 'wrappers' de otra instancia de clase que tengas.

Lo primero que vamos a hacer será crear un directiorio `app/decorators`, y a continuación añadimos esta línea de configuración al archivo `config/application.rb`:

```rb
config.autoload_paths += %W(#{config.root}/app/decoratos)
```

Esto lo que hará es que se carguen automáticamente los archivos incluídos dentro de la carpeta especificada, para que podamos utilizarlos dentro de nuestra aplicación. 

Una vez hecho esto, creamos un fichero `app/decorators/user_decorator.rb`

Y definimos la siguiente clase:

```rb
class UserDecorator
  attr_reader :user, :view_context
  def initialize(user, view_context)
    @user, @view_context = user, view_context
  end

  def name
    "#{user.first_name} #{user.last_name.first}."
  end
end
```

Lo que estamos haciendo es utilizar una nueva clase para contener la logica que maneja definir el nombre completo del usuario, para ello definimos su constructor (initializer) recibiendo como parámetro un `usuario`, y el `view_context` que nos sirve para poder tener acceso a `view helpers` integrados en Rails como `link_to`,  `content_tag`, y todos los view helpers típicos.

Más información sobre `view_context` en [este enlace](http://api.rubyonrails.org/classes/ActionView/Context.html).

Ahora que tenemos esto, usamos esta clase dentro de nuestro controlador de users:

```rb
class UsersController < ApplicationController
  def index
    @user_decorators = User.all.map{ |user| UserDecorator.new(user, view_context) }
  end
end
```

Lo que estamos haciendo es modificando cada unos de los usuarios, para que sean una instancia de la clase UserDecorator que contenga la información de cada uno de ellos. 

Y ahora en la vista, en lugar de llamar al método `name` del modelo, lo que hacemos es llamar al método `name` del `decorator`:

```erb
<h1>Users</h1>
<% @user_decorators.each do |user_decorator| %>
  <div>
    <%= user_decorator.name %>
  </div>
<% end %>
```
Al haber hecho cambios en la configuración de la aplicación, tenemos que reiniciar el servidor para que se carguen los cambios.

Podemos además añadir un método `to_s` a la clase `UserDecorator` para que cuando llamemos al método `name` no tengamos que escribir `user_decorator.name`, sino que podamos llamar directamente al objeto `user_decorator`:

```rb
class UserDecorator
  attr_reader :user, :view_context
  def initialize(user, view_context)
    @user, @view_context = user, view_context
  end

  def name
    "#{user.first_name} #{user.last_name.first}."
  end

  def to_s
    name
  end
end
```

### Más ejemplos de uso de un decorator 

```rb
class UserDecorator
  attr_reader :user, :view_context
  def initialize(user, view_context)
    @user, @view_context = user, view_context
  end


# Aquí podemos apreciar el uso de view_context, para poder utilizar
# content_tag (en este caso) 
def staff_badge
    view_context.content_tag(:span, 'Staff', class: 'badge badge-success') if user.admin?
  end

  def mod_badge
    view_context.content_tag(:span, 'Mod', class: 'badge badge-primary') if user.moderator?
  end
end
```

```erb
<% @user_decorators.each do |user_decorator| %>
  <div>
    <%= user_decorator.name %>
    <%= user_decorator.staff_badge %>
    <%= user_decorator.mod_badge %>
  </div>
<% end %>
```

![image](https://user-images.githubusercontent.com/104019638/198843778-c264209d-88cd-4693-afc7-4478ee18aae7.png)

Como hemos visto, los `decorators` son una forma de encapsular la lógica de los modelos, y de esta forma poder tener un modelo más limpio y legible.

Hay que tener en cuenta que utilizar decorators añade una capa de complejidad a nuestra aplicación, y por lo tanto, hay que utilizarlos con criterio, y solo cuando sea necesario (en una aplicación básica, pues va a ser que no 😅).

