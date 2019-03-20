
let distancia=[500,400,300,200,100]; //metres
let power=['L','H','M']; //low high max

console.log("Distancia;Power;json");
distancia.forEach(d=>{
  power.forEach(p=>{
    console.log(
      `${d};${p}; `
    )
  })
})
