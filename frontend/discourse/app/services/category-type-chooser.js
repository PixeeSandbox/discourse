import { tracked } from "@glimmer/tracking";
import Service from "@ember/service";

export default class CategoryTypeChooser extends Service {
  @tracked _selectedType = null;

  choose(typeId) {
    this._selectedType = typeId;
  }

  consume() {
    const type = this._selectedType;
    this._selectedType = null;
    return type;
  }
}
