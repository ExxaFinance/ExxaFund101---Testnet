import { deploy } from './ethers-lib'

(async () => {
  try {
    const result = await deploy('Exxafund101', [])
    console.log(`address: ${result.address}`)
  } catch (e) {
    console.log(e.message)
  }
})()
