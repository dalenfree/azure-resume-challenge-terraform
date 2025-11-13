document.addEventListener('DOMContentLoaded', () => {
    const visitorsDiv = document.getElementById('visitors');
    
    // Function to increment visitor count
    const incrementVisitorCount = async () => {
        try {
            // POST request to the API
            const postResponse = await fetch('https://fa96407.azurewebsites.net/api/http_trigger', {
            //const postResponse = await fetch('http://localhost:7071/api/http_trigger', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({})
            });

            // Check if the request was successful
            if (!postResponse.ok) {
                throw new Error('Network response was not ok');
            }

            // Fetch the JSON result
            const jsonResponse = await postResponse.json();

            // Show only the number in the div
            visitorsDiv.textContent = jsonResponse.new_count;

        } catch (error) {
            console.error('There was a problem with the fetch operation:', error);
            visitorsDiv.textContent = 'Error';
        }
    };

    incrementVisitorCount();
});
