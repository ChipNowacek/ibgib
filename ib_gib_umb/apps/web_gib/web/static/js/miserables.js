export function getData() {
  let data =
  {
    "nodes": [
      {"id": "Myriel", "group": 1},
      {"id": "Napoleon", "group": 1},
      {"id": "Mlle.Baptistine", "group": 1},
      {"id": "Mme.Magloire", "group": 1},
      {"id": "CountessdeLo", "group": 1},
      {"id": "Geborand", "group": 1},
      {"id": "Champtercier", "group": 1},
      {"id": "Cravatte", "group": 1},
      {"id": "Joly", "group": 8},
      {"id": "Grantaire", "group": 8},
      {"id": "MotherPlutarch", "group": 9},
      {"id": "Gueulemer", "group": 4},
      {"id": "Babet", "group": 4},
      {"id": "Claquesous", "group": 4},
      {"id": "Montparnasse", "group": 4},
      {"id": "Toussaint", "group": 5},
      {"id": "Child1", "group": 10},
      {"id": "Child2", "group": 10},
      {"id": "Brujon", "group": 4},
      {"id": "Mme.Hucheloup", "group": 8}
    ],
    "links": [
      {"source": "Champtercier", "target": "Myriel", "value": 1},
      {"source": "Mlle.Baptistine", "target": "Myriel", "value": 8},
      {"source": "Mme.Magloire", "target": "Myriel", "value": 10},
      {"source": "Mme.Magloire", "target": "Mlle.Baptistine", "value": 6},
      {"source": "CountessdeLo", "target": "Myriel", "value": 1},
      {"source": "Geborand", "target": "Myriel", "value": 1},
      {"source": "Mme.Hucheloup", "target": "Brujon", "value": 1}
    ]
  };

  return data;
}
