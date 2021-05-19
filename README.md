## JSONParser
JsonParser is a DSL implemented in ruby that can be used to parse a JSON response from any REST API. The example in this repo parses the `https://swapi.dev/api/starships/` endpoint.

## Usage

Create a file with the DSL formatted code. Then run `ruby json_parser.rb <filepath>`.

## DSL format

```
url = "https://swapi.dev/api/starships/"

JsonParser.fetch(url) do
  get "results"
  where "passengers", :==, "0"
  where "cargo_capacity", :>, "110"
  get "name"
end
```

`JSONParser.fetch(url, &block)` will fetch the URL and then apply the passed in block to filter which fields from the response to return.

All filters are additive meaning the filter applies to the result of the previous filter, not the response as a whole. So in the example above, the `where` command would filter only on the results field, instead of the entire API response.

### Filter methods

- `get(key)` will return a particular field from the response based on the 'key' param.
- `where(key, method, value` will filter the response to only select entries in the 'key' field that return true for the `method` passed in. For example, `where "key", ":==", "value"` will find all keys that equal to "value". Other comparison methods such as `:>=, :<=, :>, :<, :!=` can also be used.

### Design decisions

Fields can be various data types (array, hash, string, integer). I created `HashResponse` and `ArrayResponse` classes to handle filtering for each data type respectively. For strings and integers which do not support filtering, I have a generic `DataResponse` class that returns the value of the fields.

Rather than doing a type check in multiple places of the code to get the appropriate response class, I applied the factory pattern to return the correct response class. The `ApiResponse` class has a single class method that is responsible for returning the correct response class. The method uses `is_a?` to check the type of the data. This allows me to confirm that the data returned by the API is in a format that I can work with.

`HashResponse` and `ArrayResponse` act as 'Response' duck types since they both implement the `response`, `get`, and `where` methods. I chose to rely on duck types rather than inheritance because while they share an interface, they don't share many implementation details. Furthermore, the `DataResponse` class doesn't adhere to interface as it doesn't implement `get` or `where`. Therefore, it would be awkward to create a base class where at least one class overrides all the methods.

`DataResponse` doesn't need to implement `get` and `where`.Instead of having a confusing error like

```
undefined method `get' for #<DataResponse:0x00007ffac4851cb0 @response=36>
```

when `get` or `where` is called on a `DataResponse` class, I used `method_missing` to return a more appropriate error message for the DSL.

Since this was a quick prototype to try and see how creating a DSL works, I haven't implemented extensive error checking or security checks. I don't guard for the case where the API fetch fails. Furthermore, this DSL uses `eval` which allows a person to execute arbitrary Ruby code and should be used with caution.
