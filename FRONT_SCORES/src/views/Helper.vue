<template>
  <div>
      <h1>helper</h1>
  </div>
</template>

<script>
export default {
    async mounted(){
        try {   

            var url = "https://www.libroazul.com/ws/wslibroazul.asmx?WSDL";

            var xhr = new XMLHttpRequest();
            xhr.open("POST", url);

            xhr.setRequestHeader("Content-Type", "text/xml; charset=utf-8");            

            xhr.onreadystatechange = () => {
                if (xhr.readyState === 4) {
                    console.log("respuesta!!!!")
                    console.log(xhr.status);
                    console.log(xhr.responseText);
                }
            };

            var data = `<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
            <soap:Body>
                <IniciarSesion xmlns="http://www.libroazul.com/ws/">
                <Usuario>demoVirtual55721</Usuario>
                <Contrasena>redes*7521</Contrasena>
                </IniciarSesion>
            </soap:Body>
            </soap:Envelope>`;

            xhr.send(data);

            /*
            const url = "https://www.libroazul.com/ws/wslibroazul.asmx?WSDL"
            // const url = "https://www.libroazul.com/ws/wslibroazul.asmx?WSDL"
            
            const data =  '<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/"><soap:Body><IniciarSesion xmlns="http://www.libroazul.com/ws/"><Usuario>demoVirtual55721</Usuario><Contrasena>redes*7521</Contrasena></IniciarSesion></soap:Body></soap:Envelope>'
            
            console.log("fetch.... ")
            const response = await fetch(url, {
                method: 'POST', // *GET, POST, PUT, DELETE, etc.                
                headers: {'Content-Type': 'text/xml; charset=utf-8'},
                body: data
            });
    
            console.log("despues de fetch.... ")
            console.log(response)
            */

        } catch (error) {            
            console.error("error en ... ", error)
        }
    }
}
</script>

<style>

</style>