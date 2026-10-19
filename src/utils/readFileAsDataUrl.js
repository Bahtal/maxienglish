export async function readFileAsDataUrl(file) {
    const bytes = new Uint8Array(await file.arrayBuffer());
    const chunks = [];
    const chunkSize = 0x8000;

    for (let offset = 0; offset < bytes.length; offset += chunkSize) {
        chunks.push(String.fromCharCode(...bytes.subarray(offset, offset + chunkSize)));
    }

    const mimeType = file.type || 'application/octet-stream';
    return `data:${mimeType};base64,${btoa(chunks.join(''))}`;
}
