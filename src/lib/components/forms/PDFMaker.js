import pdfMake from "pdfmake/build/pdfmake";
import "pdfmake/build/vfs_fonts";
import { Capacitor } from "@capacitor/core";
import { Directory, Encoding, Filesystem } from "@capacitor/filesystem";
import { Share } from "@capacitor/share";
import { LeftLogo, RightLogo } from "./PDFImage";

function isBase64Image(str) {
    const regex = /^data:image\/(png|jpeg|jpg|gif|bmp|webp);base64,[A-Za-z0-9+/=]+$/;
    return typeof str === 'string' && regex.test(str);
}

function removeHtmlTags(input) {
    return input.replace(/<[^>]*>/g, '');
}

export async function generateFormPDF(template, form_data, ignoreEmptyFields = false) {
    let documentDefinition = {
        pageSize: 'LETTER',
        content: [
            {
                columns: [
                    {image: "left_logo", width: 100},
                    {text: "Ayuntamiento de Tijuana\nDirección de Bomberos Tijuana\nFormato de Registro de Atención Hospitalaria", style: 'header'},
                    {image: "right_logo", width: 100},
                ]
            }
        ],
        styles: {
            header: {
                fontSize: 16,
                alignment: 'center'
            },
            subheader: {
                fontSize: 14
            },
            normalText: {
                fontSize: 12
            },
            smallText: {
                fontSize: 10
            }
        },
        images: {
            left_logo: LeftLogo,
            right_logo: RightLogo
        }
    };

    const allFields = Object.values(template.fields).flat();
    const numColumns = 4;
    
    // Nivel superior
    let counter = 0;
    let row = [];

    const tableDefinition = (columns) => {
        return {
            style: 'smallText',
            table: {
                headerRows: 1,
                widths: Array(columns).fill('auto'),
                body: []
            }
        }
    }

    // Permite saltar a la siguiente línea
    const resetRow = () => {
        documentDefinition.content.push({columns: row, columnGap: 50});
        documentDefinition.content.push("\n");
        row = [];
        counter = 0;
    }
    
    // Cada campo se muestra en una columna
    for (const field of allFields) {
        // Cuando se sobrepasa el número de columnas se sigue a la siguiente fila
        if (counter >= numColumns) resetRow();
        const value = form_data?.data?.[field.name] ?? null;
        if (ignoreEmptyFields && field.type !== 'text' && (!value || value.length < 1)) continue;
        counter++;
        // Cada campo puede tener una distribución distinta en el pdf
        switch (field.type) {
            // Inputs básicos
            case 'input':
            case 'select':
            case 'textarea':
            case 'multiple':
                // Cuando existen valores múltiples se ponen en lista (ul: unordered list).
                if (Array.isArray(value)) 
                    row.push({width: 'auto', style: 'smallText', stack: [{text: field.label, bold: true}, {ul: value}]});
                else 
                    row.push({width: 'auto', style: 'smallText', stack: [{text: field.label, bold: true}, {text: value}]});
                break;
            // El resto de componentes se maneja en filas completas sin columnas.
            case 'text':
                resetRow();
                documentDefinition.content.push({text: `${removeHtmlTags(field.text)}`, style: 'subheader'});
                break;
            // Las tuplas tienen comportamientos distintos y se manejan con tablas.
            case 'tuple':
                resetRow();
                documentDefinition.content.push({text: field.label});
                const allowedTupleTypes = ['input', 'select', 'textarea', 'multiple'];
                let validTuples = field.tuple.filter(tuple => allowedTupleTypes.includes(tuple.type));
                let numTuples = validTuples.length;
                let tupleRow = [];
                let tupleCounter = 0;

                let tableDef = tableDefinition(numTuples);
                tableDef.table.body.push(validTuples.map(tuple => tuple.label));

                const resetTupleRow = () => {
                    tableDef.table.body.push(tupleRow);
                    tupleRow = [];
                    tupleCounter = 0;
                }
                // Validación básica
                if (!Array.isArray(value)) break;
                
                for (const tuple of value) {
                    for (const subfield of field.tuple) {
                        if (tupleCounter > numTuples) resetTupleRow();
                        tupleCounter++;
                        const subvalue = tuple[subfield.name];
                        if (!allowedTupleTypes.includes(subfield.type)) 
                            continue;
                        if (Array.isArray(subvalue))
                            tupleRow.push({ul: subvalue});
                        else 
                            tupleRow.push({text: subvalue});
                    }
                }
                if (tupleCounter > 0) resetTupleRow();
                documentDefinition.content.push(tableDef);
                break;
            case 'signature':
                resetRow();
                documentDefinition.content.push({
                    stack: [
                        { text: field.label, bold: true },
                        { text: field.nombreLabel },
                        { text: field.declaracion, style: 'smallText', alignment: 'justify' },
                        isBase64Image(value) ? 
                            { image: value, width: 200, alignment: 'center' } : 
                            {text: "—", alignment: 'center'},
                        '\n'
                    ]
                });
            default:
                break;
        }
    }
    if (counter > 0) resetRow();

    const document = pdfMake.createPdf(documentDefinition);
    if (Capacitor.getPlatform() === 'web') {
        document.open();
    } else {
        document.getBase64(async (base64Data) => {
            try {
                const filename = `Folio_.pdf`;
                await Filesystem.writeFile({
                    path: filename,
                    data: base64Data,
                    directory: Directory.External,
                });

                const fileUri = await Filesystem.getUri({
                    path: filename,
                    directory: Directory.External,
                });

                await Share.share({
                    title: filename,
                    text: 'Open or save PDF',
                    url: fileUri.uri,
                    dialogTitle: 'Open with...'
                });
            } catch (e) {
                alert("No se pudo abrir el archivo.");
            }
        });
    }
}